import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/config/app_config.dart';
import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/logging/app_logger.dart';
import 'package:poem_studio/core/network/dio_failure_mapper.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/data/datasources/asset/poem_asset_datasource.dart';
import 'package:poem_studio/features/poem/data/datasources/local/poem_local_datasource.dart';
import 'package:poem_studio/features/poem/data/datasources/remote/poem_remote_datasource.dart';
import 'package:poem_studio/features/poem/data/models/poem_asset_dto.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_record.dart';
import 'package:poem_studio/features/poem/data/models/poem_mappers.dart';
import 'package:poem_studio/features/poem/data/repositories/sync_status_tracker.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';

@LazySingleton(as: PoemRepository)
class PoemRepositoryImpl implements PoemRepository {
  PoemRepositoryImpl(
    this._assetDataSource,
    this._localDataSource,
    this._remoteDataSource,
    this._syncStatus,
    this._config,
    this._logger,
  );

  final PoemAssetDataSource _assetDataSource;
  final PoemLocalDataSource _localDataSource;
  final PoemRemoteDataSource _remoteDataSource;
  final SyncStatusTracker _syncStatus;
  final AppConfig _config;
  final AppLogger _logger;

  Future<Result<void>>? _runningSync;

  @override
  Stream<Result<List<PoemEntity>>> watchPoems() async* {
    final List<PoemAssetDto> originals;
    try {
      originals = await _assetDataSource.loadPoems();
    } on Exception catch (e, s) {
      _logger.error('Loading bundled poems failed', e, s);
      yield const Err(StorageFailure());
      return;
    }

    yield* _localDataSource.watchEdits().transform(
      StreamTransformer.fromHandlers(
        handleData: (edits, sink) => sink.add(Ok(_merge(originals, edits))),
        handleError: (error, stackTrace, sink) {
          _logger.error('Watching local edits failed', error, stackTrace);
          sink.add(const Err(StorageFailure()));
        },
      ),
    );
  }

  @override
  Future<Result<PoemEntity>> getPoemById(String id) {
    return _guardStorage('Loading poem $id', () async {
      final originals = await _assetDataSource.loadPoems();
      final index = originals.indexWhere((poem) => poem.id == id);
      if (index == -1) return const Err(NotFoundFailure());
      final edit = await _localDataSource.findEdit(id);
      return Ok(originals[index].toEntity(order: index + 1, edit: edit));
    });
  }

  @override
  Future<Result<PoemEntity>> editPoem({
    required String id,
    required String title,
    required String content,
  }) async {
    switch (await getPoemById(id)) {
      case Err(:final failure):
        return Err(failure);
      case Ok(data: final poem):
        return _guardStorage('Saving edit for $id', () async {
          final edit = PoemEditRecord(
            id: id,
            title: title,
            content: content,
            updatedAt: clock.now().toUtc(),
            isSynced: false,
          );
          await _localDataSource.saveEdit(edit);
          return Ok(
            PoemEntity(
              id: id,
              order: poem.order,
              title: title,
              content: content,
              updatedAt: edit.updatedAt,
            ),
          );
        });
    }
  }

  @override
  Future<Result<void>> syncPoems() {
    if (!_config.isSyncEnabled) return Future.value(const Ok(null));
    return _runningSync ??= _sync().whenComplete(() => _runningSync = null);
  }

  @override
  Stream<SyncStatus> watchSyncStatus() => _syncStatus.watch();

  Future<Result<void>> _sync() async {
    _syncStatus.update(SyncStatus.syncing);
    Result<void> result = const Err(StorageFailure());
    try {
      result = await _pushThenPull();
    } finally {
      _syncStatus.update(result is Ok ? SyncStatus.idle : SyncStatus.failed);
    }
    return result;
  }

  Future<Result<void>> _pushThenPull() async {
    try {
      for (final edit in await _localDataSource.pendingEdits()) {
        final stored = await _remoteDataSource.putEdit(edit.id, edit.toBody());
        await _localDataSource.acknowledge(
          sent: edit,
          stored: stored.toRecord(),
        );
      }
      final response = await _remoteDataSource.getEdits();
      await _localDataSource.mergeRemoteEdits(
        response.edits.map((edit) => edit.toRecord()).toList(),
      );
      return const Ok(null);
    } on DioException catch (e, s) {
      _logger.warning('Sync request failed', e, s);
      return Err(e.toFailure());
    } on TypeError catch (e, s) {
      _logger.error('Sync response did not match the expected schema', e, s);
      return const Err(ServerFailure());
    } on Exception catch (e, s) {
      _logger.error('Sync failed while writing local edits', e, s);
      return const Err(StorageFailure());
    }
  }

  List<PoemEntity> _merge(
    List<PoemAssetDto> originals,
    Map<String, PoemEditRecord> edits,
  ) {
    return [
      for (final (index, poem) in originals.indexed)
        poem.toEntity(order: index + 1, edit: edits[poem.id]),
    ];
  }

  Future<Result<T>> _guardStorage<T>(
    String operation,
    Future<Result<T>> Function() action,
  ) async {
    try {
      return await action();
    } on Exception catch (e, s) {
      _logger.error('$operation failed', e, s);
      return Err<T>(const StorageFailure());
    }
  }
}
