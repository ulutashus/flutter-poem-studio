import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/features/poem/data/models/poem_asset_dto.dart';

class MalformedAssetException implements Exception {
  const MalformedAssetException(this.cause);

  final Object cause;

  @override
  String toString() => 'MalformedAssetException: $cause';
}

@lazySingleton
class PoemAssetDataSource {
  const PoemAssetDataSource(this._bundle);

  static const assetPath = 'assets/data/poems.json';

  final AssetBundle _bundle;

  /// The bundle caches the parsed result, so the JSON is decoded only once.
  Future<List<PoemAssetDto>> loadPoems() {
    return _bundle.loadStructuredData(assetPath, (raw) async {
      try {
        return (jsonDecode(raw) as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(PoemAssetDto.fromJson)
            .toList(growable: false);
      } on TypeError catch (e) {
        throw MalformedAssetException(e);
      }
    });
  }
}
