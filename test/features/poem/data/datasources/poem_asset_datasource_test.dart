import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poem_studio/features/poem/data/datasources/asset/poem_asset_datasource.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._json);

  final String _json;
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    expect(key, PoemAssetDataSource.assetPath);
    return ByteData.sublistView(utf8.encode(_json));
  }
}

void main() {
  test('parses the bundled poems once and reuses the result', () async {
    final bundle = _FakeAssetBundle(
      '[{"id":"a","title":"Morning Tea","content":"Steam"},'
      '{"id":"b","title":"Paper Boats","content":"Boats"}]',
    );
    final dataSource = PoemAssetDataSource(bundle);

    final first = await dataSource.loadPoems();
    final second = await dataSource.loadPoems();

    expect(first.map((poem) => poem.id), ['a', 'b']);
    expect(first.first.title, 'Morning Tea');
    expect(second, same(first));
    expect(bundle.loads, 1);
  });

  test('wraps malformed data in MalformedAssetException', () async {
    final dataSource = PoemAssetDataSource(_FakeAssetBundle('{"oops":1}'));

    await expectLater(
      dataSource.loadPoems(),
      throwsA(isA<MalformedAssetException>()),
    );
  });
}
