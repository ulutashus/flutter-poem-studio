import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/domain/usecases/edit_poem_usecase.dart';

import '../../../../helpers/fixtures.dart';

class _MockPoemRepository extends Mock implements PoemRepository {}

void main() {
  late _MockPoemRepository repository;
  late EditPoemUseCase editPoem;

  setUp(() {
    repository = _MockPoemRepository();
    editPoem = EditPoemUseCase(repository);
    when(() => repository.syncPoems()).thenAnswer((_) async => const Ok(null));
  });

  void stubEdit(Result<PoemEntity> result) {
    when(
      () => repository.editPoem(
        id: any(named: 'id'),
        title: any(named: 'title'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('trims the input, saves it and starts a sync', () async {
    stubEdit(const Ok(morningTea));

    final result = await editPoem(id: 'a', title: ' Title ', content: ' Body ');

    expect(result, const Ok(morningTea));
    verify(() => repository.editPoem(id: 'a', title: 'Title', content: 'Body'))
        .called(1);
    verify(() => repository.syncPoems()).called(1);
  });

  test('rejects a blank title or content without touching storage', () async {
    expect(
      await editPoem(id: 'a', title: '  ', content: 'Body'),
      const Err<PoemEntity>(ValidationFailure()),
    );
    expect(
      await editPoem(id: 'a', title: 'Title', content: '\n'),
      const Err<PoemEntity>(ValidationFailure()),
    );
    verifyZeroInteractions(repository);
  });

  test('does not sync when saving fails', () async {
    stubEdit(const Err(StorageFailure()));

    final result = await editPoem(id: 'a', title: 'Title', content: 'Body');

    expect(result, const Err<PoemEntity>(StorageFailure()));
    verifyNever(() => repository.syncPoems());
  });
}
