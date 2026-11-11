import 'package:equatable/equatable.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';

sealed class PoemDetailState extends Equatable {
  const PoemDetailState();

  @override
  List<Object?> get props => [];
}

final class PoemDetailLoading extends PoemDetailState {
  const PoemDetailLoading();
}

final class PoemDetailLoaded extends PoemDetailState {
  const PoemDetailLoaded({required this.poems, required this.index});

  final List<PoemEntity> poems;
  final int index;

  PoemEntity get poem => poems[index];

  bool get hasPrevious => index > 0;

  bool get hasNext => index < poems.length - 1;

  @override
  List<Object?> get props => [poems, index];
}

final class PoemDetailError extends PoemDetailState {
  const PoemDetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
