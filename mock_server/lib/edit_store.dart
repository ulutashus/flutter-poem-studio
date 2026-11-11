class PoemEdit {
  const PoemEdit({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class EditStore {
  final _edits = <String, PoemEdit>{};

  List<PoemEdit> all() => _edits.values.toList();

  /// Last write wins: an older edit never replaces a newer one.
  PoemEdit put(PoemEdit edit) {
    final current = _edits[edit.id];
    if (current != null && current.updatedAt.isAfter(edit.updatedAt)) {
      return current;
    }
    return _edits[edit.id] = edit;
  }
}
