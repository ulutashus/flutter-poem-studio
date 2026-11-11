import 'package:drift/drift.dart';

import 'package:poem_studio/features/poem/data/datasources/local/poem_edits_table.dart';

part 'poem_database.g.dart';

@DriftDatabase(tables: [PoemEdits])
class PoemDatabase extends _$PoemDatabase {
  PoemDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
