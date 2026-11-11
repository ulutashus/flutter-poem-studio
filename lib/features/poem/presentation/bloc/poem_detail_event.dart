import 'dart:typed_data';

import 'package:equatable/equatable.dart';

sealed class PoemDetailEvent extends Equatable {
  const PoemDetailEvent();

  @override
  List<Object?> get props => [];
}

final class PoemDetailSubscriptionRequested extends PoemDetailEvent {
  const PoemDetailSubscriptionRequested(this.poemId);

  final String poemId;

  @override
  List<Object?> get props => [poemId];
}

final class PoemDetailPageChanged extends PoemDetailEvent {
  const PoemDetailPageChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

final class PoemDetailTextShareRequested extends PoemDetailEvent {
  const PoemDetailTextShareRequested();
}

final class PoemDetailImageShareRequested extends PoemDetailEvent {
  const PoemDetailImageShareRequested(this.pngBytes);

  final Uint8List pngBytes;

  @override
  List<Object?> get props => [pngBytes];
}
