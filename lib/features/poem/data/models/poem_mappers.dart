import 'package:poem_studio/features/poem/data/models/poem_asset_dto.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_dto.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_record.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';

extension PoemAssetDtoMapper on PoemAssetDto {
  PoemEntity toEntity({required int order, PoemEditRecord? edit}) {
    return PoemEntity(
      id: id,
      order: order,
      title: edit?.title ?? title,
      content: edit?.content ?? content,
      updatedAt: edit?.updatedAt,
    );
  }
}

extension PoemEditDtoMapper on PoemEditDto {
  /// Anything that came from the server is, by definition, synced.
  PoemEditRecord toRecord() => PoemEditRecord(
    id: id,
    title: title,
    content: content,
    updatedAt: updatedAt,
    isSynced: true,
  );
}

extension PoemEditRecordMapper on PoemEditRecord {
  PoemEditBodyDto toBody() =>
      PoemEditBodyDto(title: title, content: content, updatedAt: updatedAt);
}
