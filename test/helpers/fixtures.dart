import 'package:poem_studio/features/poem/data/models/poem_asset_dto.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';

const morningTea = PoemEntity(
  id: 'a',
  order: 1,
  title: 'Morning Tea',
  content: 'Steam climbs slowly from the cup,\nthe kettle hums its quiet tune.',
);

const paperBoats = PoemEntity(
  id: 'b',
  order: 2,
  title: 'Paper Boats',
  content: "We folded boats from yesterday's news\n\nand set them down.",
);

const poems = [morningTea, paperBoats];

const assetPoems = [
  PoemAssetDto(id: 'a', title: 'Morning Tea', content: 'Steam climbs slowly'),
  PoemAssetDto(id: 'b', title: 'Paper Boats', content: 'We folded boats'),
];
