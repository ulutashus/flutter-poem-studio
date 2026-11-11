import 'package:json_annotation/json_annotation.dart';

part 'poem_asset_dto.g.dart';

@JsonSerializable(createToJson: false)
class PoemAssetDto {
  const PoemAssetDto({
    required this.id,
    required this.title,
    required this.content,
  });

  factory PoemAssetDto.fromJson(Map<String, dynamic> json) =>
      _$PoemAssetDtoFromJson(json);

  final String id;
  final String title;
  final String content;
}
