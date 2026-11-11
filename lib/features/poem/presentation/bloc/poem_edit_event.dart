import 'package:equatable/equatable.dart';

sealed class PoemEditEvent extends Equatable {
  const PoemEditEvent();

  @override
  List<Object?> get props => [];
}

final class PoemEditStarted extends PoemEditEvent {
  const PoemEditStarted(this.poemId);

  final String poemId;

  @override
  List<Object?> get props => [poemId];
}

final class PoemEditSaveRequested extends PoemEditEvent {
  const PoemEditSaveRequested({required this.title, required this.content});

  final String title;
  final String content;

  @override
  List<Object?> get props => [title, content];
}
