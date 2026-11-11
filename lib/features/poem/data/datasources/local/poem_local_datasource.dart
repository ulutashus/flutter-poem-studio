import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/features/poem/data/datasources/local/poem_database.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_record.dart';

@lazySingleton
class PoemLocalDataSource {
  const PoemLocalDataSource(this._db);

  final PoemDatabase _db;

  Stream<Map<String, PoemEditRecord>> watchEdits() {
    return _db
        .select(_db.poemEdits)
        .watch()
        .map((rows) => {for (final row in rows) row.id: _toRecord(row)});
  }

  Future<PoemEditRecord?> findEdit(String id) async {
    final row = await _byId(id).getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  Future<List<PoemEditRecord>> pendingEdits() async {
    final query = _db.select(_db.poemEdits)
      ..where((t) => t.isSynced.equals(false));
    return (await query.get()).map(_toRecord).toList();
  }

  Future<void> saveEdit(PoemEditRecord edit) {
    return _db.into(_db.poemEdits).insertOnConflictUpdate(_toCompanion(edit));
  }

  /// Stores the server's copy of [sent], unless the poem was edited again while the request was in flight.
  Future<void> acknowledge({
    required PoemEditRecord sent,
    required PoemEditRecord stored,
  }) {
    return _db.transaction(() async {
      final current = await _byId(sent.id).getSingleOrNull();
      if (current == null ||
          !current.updatedAt.isAtSameMomentAs(sent.updatedAt)) {
        return;
      }
      await saveEdit(stored);
    });
  }

  /// Last write wins by `updatedAt`; an edit still pending on the device is never overwritten.
  Future<void> mergeRemoteEdits(List<PoemEditRecord> remote) {
    return _db.transaction(() async {
      final rows = await _db.select(_db.poemEdits).get();
      final local = {for (final row in rows) row.id: row};
      for (final edit in remote) {
        final current = local[edit.id];
        final keepLocal =
            current != null &&
            (!current.isSynced || !edit.updatedAt.isAfter(current.updatedAt));
        if (!keepLocal) await saveEdit(edit);
      }
    });
  }

  SimpleSelectStatement<$PoemEditsTable, PoemEdit> _byId(String id) =>
      _db.select(_db.poemEdits)..where((t) => t.id.equals(id));

  PoemEditRecord _toRecord(PoemEdit row) => PoemEditRecord(
    id: row.id,
    title: row.title,
    content: row.content,
    updatedAt: row.updatedAt,
    isSynced: row.isSynced,
  );

  PoemEditsCompanion _toCompanion(PoemEditRecord edit) =>
      PoemEditsCompanion.insert(
        id: edit.id,
        title: edit.title,
        content: edit.content,
        updatedAt: edit.updatedAt,
        isSynced: Value(edit.isSynced),
      );
}
