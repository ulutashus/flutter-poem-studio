import 'package:equatable/equatable.dart';

class PoemEntity extends Equatable {
  const PoemEntity({
    required this.id,
    required this.order,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  final String id;

  /// 1-based position in the bundled collection; stable across searches.
  final int order;
  final String title;
  final String content;

  /// Null when the poem has never been edited.
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, order, title, content, updatedAt];
}
