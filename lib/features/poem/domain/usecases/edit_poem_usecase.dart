import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';

/// Saves a trimmed, non-empty edit and starts a background sync without waiting for it.
@injectable
class EditPoemUseCase {
  const EditPoemUseCase(this._repository);

  final PoemRepository _repository;

  Future<Result<PoemEntity>> call({
    required String id,
    required String title,
    required String content,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();
    if (trimmedTitle.isEmpty || trimmedContent.isEmpty) {
      return const Err(ValidationFailure());
    }

    final result = await _repository.editPoem(
      id: id,
      title: trimmedTitle,
      content: trimmedContent,
    );
    if (result is Ok) unawaited(_repository.syncPoems());
    return result;
  }
}
