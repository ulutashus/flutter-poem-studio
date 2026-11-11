import 'package:flutter_test/flutter_test.dart';

import 'package:poem_studio/features/poem/domain/usecases/search_poems_usecase.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  const search = SearchPoemsUseCase();

  test('returns every poem for a blank query', () {
    expect(search(poems, '   '), poems);
  });

  test('matches a numeric query against the poem number only', () {
    expect(search(poems, ' 2 '), [paperBoats]);
    expect(search(poems, '7'), isEmpty);
  });

  test('matches title or content, ignoring case', () {
    expect(search(poems, 'MORNING'), [morningTea]);
    expect(search(poems, 'folded'), [paperBoats]);
    expect(search(poems, 'lighthouse'), isEmpty);
  });
}
