import 'package:equatable/equatable.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';

sealed class PoemEditState extends Equatable {
  const PoemEditState();

  @override
  List<Object?> get props => [];
}

final class PoemEditLoading extends PoemEditState {
  const PoemEditLoading();
}

final class PoemEditReady extends PoemEditState {
  const PoemEditReady({
    required this.poem,
    this.isSaving = false,
    this.saveFailure,
  });

  final PoemEntity poem;
  final bool isSaving;
  final Failure? saveFailure;

  @override
  List<Object?> get props => [poem, isSaving, saveFailure];
}

final class PoemEditSaved extends PoemEditState {
  const PoemEditSaved(this.poem);

  final PoemEntity poem;

  @override
  List<Object?> get props => [poem];
}

final class PoemEditError extends PoemEditState {
  const PoemEditError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
