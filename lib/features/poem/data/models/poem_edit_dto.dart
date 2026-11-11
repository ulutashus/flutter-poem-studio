import 'package:json_annotation/json_annotation.dart';

part 'poem_edit_dto.g.dart';

@JsonSerializable()
class PoemEditDto {
  const PoemEditDto({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  factory PoemEditDto.fromJson(Map<String, dynamic> json) =>
      _$PoemEditDtoFromJson(json);

  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$PoemEditDtoToJson(this);
}

@JsonSerializable(createToJson: false)
class PoemEditsResponseDto {
  const PoemEditsResponseDto({required this.edits});

  factory PoemEditsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PoemEditsResponseDtoFromJson(json);

  final List<PoemEditDto> edits;
}

@JsonSerializable(createFactory: false)
class PoemEditBodyDto {
  const PoemEditBodyDto({
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String title;
  final String content;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$PoemEditBodyDtoToJson(this);
}
