import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/domain/usecases/search_poems_usecase.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_state.dart';

import '../../../../helpers/fixtures.dart';

class _MockRepository extends Mock implements PoemRepository {}

void main() {
  late _MockRepository repository;
  late StreamController<Result<List<PoemEntity>>> source;

  setUp(() {
    repository = _MockRepository();
    source = StreamController();
    when(() => repository.watchPoems()).thenAnswer((_) => source.stream);
  });

  // A single-subscription controller nobody listened to never completes close().
  tearDown(() => unawaited(source.close()));

  PoemListBloc build() => PoemListBloc(repository, const SearchPoemsUseCase());

  blocTest<PoemListBloc, PoemListState>(
    'shows every poem once the collection arrives',
    build: build,
    act: (bloc) {
      bloc.add(const PoemListSubscriptionRequested());
      source.add(const Ok(poems));
    },
    expect: () => const [
      PoemListState(
        status: PoemListStatus.success,
        poems: poems,
        visiblePoems: poems,
      ),
    ],
  );

  blocTest<PoemListBloc, PoemListState>(
    'filters by the debounced query',
    build: build,
    seed: () => const PoemListState(
      status: PoemListStatus.success,
      poems: poems,
      visiblePoems: poems,
    ),
    act: (bloc) => bloc
      ..add(const PoemListQueryChanged('pa'))
      ..add(const PoemListQueryChanged('paper')),
    // Waiting exactly the debounce races the timer on slow CI runners.
    wait: PoemListBloc.searchDebounce * 2,
    expect: () => const [
      PoemListState(
        status: PoemListStatus.success,
        poems: poems,
        visiblePoems: [paperBoats],
        query: 'paper',
      ),
    ],
  );

  blocTest<PoemListBloc, PoemListState>(
    'keeps the active query when the collection changes',
    build: build,
    seed: () => const PoemListState(query: 'morning'),
    act: (bloc) {
      bloc.add(const PoemListSubscriptionRequested());
      source.add(const Ok(poems));
    },
    expect: () => const [
      PoemListState(
        status: PoemListStatus.success,
        poems: poems,
        visiblePoems: [morningTea],
        query: 'morning',
      ),
    ],
  );

  blocTest<PoemListBloc, PoemListState>(
    'reports a failure from the collection stream',
    build: build,
    act: (bloc) {
      bloc.add(const PoemListSubscriptionRequested());
      source.add(const Err(StorageFailure()));
    },
    expect: () => const [
      PoemListState(status: PoemListStatus.failure, failure: StorageFailure()),
    ],
  );
}
