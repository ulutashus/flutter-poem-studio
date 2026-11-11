import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/domain/usecases/edit_poem_usecase.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_state.dart';

import '../../../../helpers/fixtures.dart';

class _MockRepository extends Mock implements PoemRepository {}

class _MockEditPoem extends Mock implements EditPoemUseCase {}

void main() {
  late _MockRepository repository;
  late _MockEditPoem editPoem;

  const saved = PoemEntity(id: 'a', order: 1, title: 'New', content: 'Body');

  setUp(() {
    repository = _MockRepository();
    editPoem = _MockEditPoem();
  });

  void stubEdit(Result<PoemEntity> result) {
    when(
      () => editPoem(
        id: any(named: 'id'),
        title: any(named: 'title'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async => result);
  }

  PoemEditBloc build() => PoemEditBloc(repository, editPoem);

  blocTest<PoemEditBloc, PoemEditState>(
    'loads the poem to edit',
    setUp: () =>
        when(() => repository.getPoemById('a'))
            .thenAnswer((_) async => const Ok(morningTea)),
    build: build,
    act: (bloc) => bloc.add(const PoemEditStarted('a')),
    expect: () => const [PoemEditLoading(), PoemEditReady(poem: morningTea)],
  );

  blocTest<PoemEditBloc, PoemEditState>(
    'reports a poem that cannot be loaded',
    setUp: () =>
        when(() => repository.getPoemById('a'))
            .thenAnswer((_) async => const Err(NotFoundFailure())),
    build: build,
    act: (bloc) => bloc.add(const PoemEditStarted('a')),
    expect: () => const [PoemEditLoading(), PoemEditError(NotFoundFailure())],
  );

  blocTest<PoemEditBloc, PoemEditState>(
    'saves the edit and finishes',
    setUp: () => stubEdit(const Ok(saved)),
    build: build,
    seed: () => const PoemEditReady(poem: morningTea),
    act: (bloc) =>
        bloc.add(const PoemEditSaveRequested(title: 'New', content: 'Body')),
    expect: () => const [
      PoemEditReady(poem: morningTea, isSaving: true),
      PoemEditSaved(saved),
    ],
    verify: (_) =>
        verify(() => editPoem(id: 'a', title: 'New', content: 'Body'))
            .called(1),
  );

  blocTest<PoemEditBloc, PoemEditState>(
    'stays editable and exposes the failure when saving fails',
    setUp: () => stubEdit(const Err(StorageFailure())),
    build: build,
    seed: () => const PoemEditReady(poem: morningTea),
    act: (bloc) =>
        bloc.add(const PoemEditSaveRequested(title: 'New', content: 'Body')),
    expect: () => const [
      PoemEditReady(poem: morningTea, isSaving: true),
      PoemEditReady(poem: morningTea, saveFailure: StorageFailure()),
    ],
  );

  blocTest<PoemEditBloc, PoemEditState>(
    'ignores save requests before the poem is loaded',
    build: build,
    act: (bloc) =>
        bloc.add(const PoemEditSaveRequested(title: 'New', content: 'Body')),
    expect: () => const <PoemEditState>[],
    verify: (_) => verifyZeroInteractions(editPoem),
  );
}
