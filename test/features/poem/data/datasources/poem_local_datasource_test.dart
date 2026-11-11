import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poem_studio/features/poem/data/datasources/local/poem_database.dart';
import 'package:poem_studio/features/poem/data/datasources/local/poem_local_datasource.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_record.dart';

PoemEditRecord _record(
  String content,
  DateTime updatedAt, {
  bool isSynced = true,
}) => PoemEditRecord(
  id: 'a',
  title: 'Title',
  content: content,
  updatedAt: updatedAt,
  isSynced: isSynced,
);

void main() {
  final older = DateTime.utc(2026, 1, 1, 10);
  final newer = DateTime.utc(2026, 1, 1, 11);

  late PoemDatabase database;
  late PoemLocalDataSource dataSource;

  setUp(() {
    database = PoemDatabase(NativeDatabase.memory());
    dataSource = PoemLocalDataSource(database);
  });

  tearDown(() => database.close());

  test('round-trips an edit with sub-second precision', () async {
    final edit = _record(
      'Body',
      DateTime.utc(2026, 1, 1, 10, 0, 0, 123, 456),
      isSynced: false,
    );

    await dataSource.saveEdit(edit);
    final stored = await dataSource.findEdit('a');

    expect(stored!.content, 'Body');
    expect(stored.updatedAt.isAtSameMomentAs(edit.updatedAt), isTrue);
    expect(await dataSource.pendingEdits(), hasLength(1));
  });

  test('watchEdits emits again after every change', () async {
    final edits = StreamIterator(dataSource.watchEdits());
    addTearDown(edits.cancel);

    expect(await edits.moveNext(), isTrue);
    expect(edits.current, isEmpty);

    await dataSource.saveEdit(_record('Body', older));

    expect(await edits.moveNext(), isTrue);
    expect(edits.current.keys, ['a']);
  });

  group('acknowledge', () {
    test('stores the server copy as synced', () async {
      final sent = _record('Mine', older, isSynced: false);
      await dataSource.saveEdit(sent);

      await dataSource.acknowledge(sent: sent, stored: _record('Mine', older));

      expect((await dataSource.findEdit('a'))!.isSynced, isTrue);
      expect(await dataSource.pendingEdits(), isEmpty);
    });

    test('keeps a newer local edit pending', () async {
      final sent = _record('Sent', older, isSynced: false);
      await dataSource.saveEdit(
        _record('Edited again', newer, isSynced: false),
      );

      await dataSource.acknowledge(sent: sent, stored: _record('Sent', older));

      final current = (await dataSource.findEdit('a'))!;
      expect(current.content, 'Edited again');
      expect(current.isSynced, isFalse);
    });
  });

  group('mergeRemoteEdits', () {
    test('inserts edits that do not exist locally', () async {
      await dataSource.mergeRemoteEdits([_record('Remote', older)]);

      expect((await dataSource.findEdit('a'))!.content, 'Remote');
    });

    test('replaces an older synced edit', () async {
      await dataSource.saveEdit(_record('Local', older));

      await dataSource.mergeRemoteEdits([_record('Remote', newer)]);

      expect((await dataSource.findEdit('a'))!.content, 'Remote');
    });

    test('keeps a synced edit that is newer than the remote one', () async {
      await dataSource.saveEdit(_record('Local', newer));

      await dataSource.mergeRemoteEdits([_record('Remote', older)]);

      expect((await dataSource.findEdit('a'))!.content, 'Local');
    });

    test('never overwrites a pending edit', () async {
      await dataSource.saveEdit(_record('Pending', older, isSynced: false));

      await dataSource.mergeRemoteEdits([_record('Remote', newer)]);

      expect((await dataSource.findEdit('a'))!.content, 'Pending');
    });
  });
}
