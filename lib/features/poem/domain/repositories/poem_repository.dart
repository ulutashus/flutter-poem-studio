import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';

abstract interface class PoemRepository {
  /// Emits the full collection with local edits applied, and again whenever an edit changes.
  Stream<Result<List<PoemEntity>>> watchPoems();

  Future<Result<PoemEntity>> getPoemById(String id);

  /// Stores the edit locally; it reaches the server on the next [syncPoems].
  Future<Result<PoemEntity>> editPoem({
    required String id,
    required String title,
    required String content,
  });

  /// Pushes pending edits, then pulls newer ones. Concurrent calls share one run.
  Future<Result<void>> syncPoems();

  Stream<SyncStatus> watchSyncStatus();
}
