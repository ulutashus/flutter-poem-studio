import 'package:injectable/injectable.dart';

import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';

/// A numeric query matches the poem number; anything else matches title or content, ignoring case.
@injectable
class SearchPoemsUseCase {
  const SearchPoemsUseCase();

  List<PoemEntity> call(List<PoemEntity> poems, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return poems;

    final number = int.tryParse(trimmed);
    if (number != null) {
      return poems.where((poem) => poem.order == number).toList();
    }

    final needle = trimmed.toLowerCase();
    return poems
        .where(
          (poem) =>
              poem.title.toLowerCase().contains(needle) ||
              poem.content.toLowerCase().contains(needle),
        )
        .toList();
  }
}
