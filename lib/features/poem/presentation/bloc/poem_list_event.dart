import 'package:equatable/equatable.dart';

sealed class PoemListEvent extends Equatable {
  const PoemListEvent();

  @override
  List<Object?> get props => [];
}

final class PoemListSubscriptionRequested extends PoemListEvent {
  const PoemListSubscriptionRequested();
}

final class PoemListQueryChanged extends PoemListEvent {
  const PoemListQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
