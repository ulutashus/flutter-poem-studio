import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/config/app_config.dart';
import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/data/datasources/asset/poem_asset_datasource.dart';
import 'package:poem_studio/features/poem/data/datasources/local/poem_database.dart';
import 'package:poem_studio/features/poem/data/datasources/local/poem_local_datasource.dart';
import 'package:poem_studio/features/poem/data/datasources/remote/poem_remote_datasource.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_dto.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_record.dart';
import 'package:poem_studio/features/poem/data/repositories/poem_repository_impl.dart';
import 'package:poem_studio/features/poem/data/repositories/sync_status_tracker.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/silent_logger.dart';

class _MockAssets extends Mock implements PoemAssetDataSource {}

class _MockRemote extends Mock implements PoemRemoteDataSource {}

class _FakeBody extends Fake implements PoemEditBodyDto {}

const _enabled = AppConfig(poemsBaseUrl: 'https://api.test', poemsApiKey: 'k');
const _disabled = AppConfig(poemsBaseUrl: '', poemsApiKey: '');

final _t1 = DateTime.utc(2026, 1, 1, 10);
final _t2 = DateTime.utc(2026, 1, 1, 11);

DioException _status(int code) {
  final options = RequestOptions();
  return DioException.badResponse(
    statusCode: code,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: code),
  );
}

PoemEditDto _dto(String content, DateTime at) =>
    PoemEditDto(id: 'a', title: 'Morning Tea', content: content, updatedAt: at);

void main() {
  setUpAll(() => registerFallbackValue(_FakeBody()));

  late PoemDatabase database;
  late PoemLocalDataSource local;
  late _MockAssets assets;
  late _MockRemote remote;
  late SyncStatusTracker tracker;
  late SilentLogger logger;

  PoemRepositoryImpl repository({AppConfig config = _enabled}) =>
      PoemRepositoryImpl(assets, local, remote, tracker, config, logger);

  setUp(() {
    database = PoemDatabase(NativeDatabase.memory());
    local = PoemLocalDataSource(database);
    assets = _MockAssets();
    remote = _MockRemote();
    tracker = SyncStatusTracker();
    logger = SilentLogger();
    when(() => assets.loadPoems()).thenAnswer((_) async => assetPoems);
    when(() => remote.getEdits())
        .thenAnswer((_) async => const PoemEditsResponseDto(edits: []));
  });

  tearDown(() async {
    await tracker.dispose();
    await database.close();
  });

  group('watchPoems', () {
    test('numbers the bundled poems and re-emits after an edit', () async {
      final repo = repository();
      final emissions = StreamIterator(repo.watchPoems());
      addTearDown(emissions.cancel);

      expect(await emissions.moveNext(), isTrue);
      final first = (emissions.current as Ok<List<PoemEntity>>).data;
      expect(first.map((poem) => (poem.order, poem.title)), [
        (1, 'Morning Tea'),
        (2, 'Paper Boats'),
      ]);

      await withClock(
        Clock.fixed(_t1),
        () => repo.editPoem(id: 'b', title: 'Boats', content: 'Edited'),
      );

      expect(await emissions.moveNext(), isTrue);
      final edited = (emissions.current as Ok<List<PoemEntity>>).data[1];
      expect(edited.title, 'Boats');
      expect(edited.updatedAt, _t1);
    });

    test('reports a StorageFailure when the bundle cannot be read', () {
      when(() => assets.loadPoems()).thenThrow(const FormatException('broken'));

      expect(
        repository().watchPoems(),
        emitsInOrder([
          const Err<List<PoemEntity>>(StorageFailure()),
          emitsDone,
        ]),
      );
    });
  });

  group('malformed bundle', () {
    test('reports a StorageFailure instead of a stream error', () {
      when(() => assets.loadPoems())
          .thenThrow(const MalformedAssetException('bad'));

      expect(
        repository().watchPoems(),
        emitsInOrder([
          const Err<List<PoemEntity>>(StorageFailure()),
          emitsDone,
        ]),
      );
    });
  });

  group('getPoemById', () {
    test('applies a stored edit', () async {
      await local.saveEdit(
        PoemEditRecord(
          id: 'a',
          title: 'Tea',
          content: 'Edited',
          updatedAt: _t1,
          isSynced: true,
        ),
      );

      final result = await repository().getPoemById('a');

      expect(
        result,
        Ok(
          PoemEntity(
            id: 'a',
            order: 1,
            title: 'Tea',
            content: 'Edited',
            updatedAt: _t1,
          ),
        ),
      );
    });

    test('returns NotFoundFailure for an unknown id', () async {
      expect(
        await repository().getPoemById('missing'),
        const Err<PoemEntity>(NotFoundFailure()),
      );
    });
  });

  group('editPoem', () {
    test('stores a pending edit stamped with the current time', () async {
      final result = await withClock(
        Clock.fixed(_t1),
        () => repository().editPoem(id: 'a', title: 'T', content: 'C'),
      );

      expect(
        result,
        Ok(
          PoemEntity(
            id: 'a',
            order: 1,
            title: 'T',
            content: 'C',
            updatedAt: _t1,
          ),
        ),
      );
      final pending = await local.pendingEdits();
      expect(pending.single.content, 'C');
    });

    test('does not store edits for an unknown poem', () async {
      final result = await repository().editPoem(
        id: 'missing',
        title: 'T',
        content: 'C',
      );

      expect(result, const Err<PoemEntity>(NotFoundFailure()));
      expect(await local.pendingEdits(), isEmpty);
    });
  });

  group('syncPoems', () {
    Future<void> savePending(String content, DateTime at) => local.saveEdit(
      PoemEditRecord(
        id: 'a',
        title: 'Morning Tea',
        content: content,
        updatedAt: at,
        isSynced: false,
      ),
    );

    test('pushes pending edits and marks them synced', () async {
      await savePending('Mine', _t1);
      when(() => remote.putEdit('a', any()))
          .thenAnswer((_) async => _dto('Mine', _t1));

      final result = await repository().syncPoems();

      expect(result, const Ok<void>(null));
      expect(await local.pendingEdits(), isEmpty);
      final body =
          verify(() => remote.putEdit('a', captureAny())).captured.single
              as PoemEditBodyDto;
      expect(body.content, 'Mine');
    });

    test('adopts the copy the server kept when it differs', () async {
      await savePending('Mine', _t1);
      when(() => remote.putEdit('a', any()))
          .thenAnswer((_) async => _dto('Theirs', _t2));

      await repository().syncPoems();

      final stored = await local.findEdit('a');
      expect((stored!.content, stored.isSynced), ('Theirs', true));
    });

    test('pulls remote edits after pushing', () async {
      when(() => remote.getEdits()).thenAnswer(
        (_) async => PoemEditsResponseDto(edits: [_dto('Remote', _t2)]),
      );

      await repository().syncPoems();

      expect((await local.findEdit('a'))!.content, 'Remote');
    });

    test('maps HTTP failures and reports the failed status', () async {
      when(() => remote.getEdits()).thenThrow(_status(401));
      final repo = repository();
      final statuses = expectLater(
        repo.watchSyncStatus(),
        emitsInOrder([SyncStatus.idle, SyncStatus.syncing, SyncStatus.failed]),
      );

      final result = await repo.syncPoems();

      expect(result, const Err<void>(UnauthorizedFailure()));
      await statuses;
    });

    test(
      'maps a schema mismatch to ServerFailure and leaves syncing',
      () async {
        when(() => remote.getEdits()).thenThrow(TypeError());
        final repo = repository();
        final statuses = expectLater(
          repo.watchSyncStatus(),
          emitsInOrder([
            SyncStatus.idle,
            SyncStatus.syncing,
            SyncStatus.failed,
          ]),
        );

        final result = await repo.syncPoems();

        expect(result, const Err<void>(ServerFailure()));
        await statuses;
      },
    );

    test('returns to idle after a successful run', () async {
      final repo = repository();
      final statuses = expectLater(
        repo.watchSyncStatus(),
        emitsInOrder([SyncStatus.idle, SyncStatus.syncing, SyncStatus.idle]),
      );

      await repo.syncPoems();

      await statuses;
    });

    test('shares one run between concurrent callers', () async {
      final gate = Completer<PoemEditsResponseDto>();
      when(() => remote.getEdits()).thenAnswer((_) => gate.future);
      final repo = repository();

      final first = repo.syncPoems();
      final second = repo.syncPoems();
      gate.complete(const PoemEditsResponseDto(edits: []));

      expect(await Future.wait([first, second]), [
        const Ok<void>(null),
        const Ok<void>(null),
      ]);
      verify(() => remote.getEdits()).called(1);
    });

    test('is a no-op when no server is configured', () async {
      final result = await repository(config: _disabled).syncPoems();

      expect(result, const Ok<void>(null));
      verifyZeroInteractions(remote);
    });
  });
}
