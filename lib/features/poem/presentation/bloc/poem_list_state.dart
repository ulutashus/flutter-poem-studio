import 'package:equatable/equatable.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';

enum PoemListStatus { loading, success, failure }

/// A single state class, because the search query must survive every status change.
final class PoemListState extends Equatable {
  const PoemListState({
    this.status = PoemListStatus.loading,
    this.poems = const [],
    this.visiblePoems = const [],
    this.query = '',
    this.failure,
  });

  final PoemListStatus status;
  final List<PoemEntity> poems;
  final List<PoemEntity> visiblePoems;
  final String query;
  final Failure? failure;

  @override
  List<Object?> get props => [status, poems, visiblePoems, query, failure];
}
