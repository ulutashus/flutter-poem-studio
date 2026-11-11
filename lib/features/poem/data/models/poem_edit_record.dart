import 'package:equatable/equatable.dart';

/// A user edit as stored on the device.
class PoemEditRecord extends Equatable {
  const PoemEditRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    required this.isSynced,
  });

  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final bool isSynced;

  @override
  List<Object?> get props => [id, title, content, updatedAt, isSynced];
}
