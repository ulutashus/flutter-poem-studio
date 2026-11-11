import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/core/share/share_service.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_state.dart';

import '../../../../helpers/fixtures.dart';

class _MockRepository extends Mock implements PoemRepository {}

class _MockShareService extends Mock implements ShareService {}

void main() {
  late _MockRepository repository;
  late _MockShareService shareService;
  late StreamController<Result<List<PoemEntity>>> source;

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    repository = _MockRepository();
    shareService = _MockShareService();
    source = StreamController();
    when(() => repository.watchPoems()).thenAnswer((_) => source.stream);
    when(() => shareService.shareText(any(), subject: any(named: 'subject')))
        .thenAnswer((_) async {});
    when(() => shareService.shareImage(any(), subject: any(named: 'subject')))
        .thenAnswer((_) async {});
  });

  // A single-subscription controller nobody listened to never completes close().
  tearDown(() => unawaited(source.close()));

  PoemDetailBloc build() => PoemDetailBloc(repository, shareService);

  blocTest<PoemDetailBloc, PoemDetailState>(
    'opens on the requested poem',
    build: build,
    act: (bloc) {
      bloc.add(const PoemDetailSubscriptionRequested('b'));
      source.add(const Ok(poems));
    },
    expect: () => const [PoemDetailLoaded(poems: poems, index: 1)],
  );

  blocTest<PoemDetailBloc, PoemDetailState>(
    'reports NotFoundFailure for an unknown poem',
    build: build,
    act: (bloc) {
      bloc.add(const PoemDetailSubscriptionRequested('missing'));
      source.add(const Ok(poems));
    },
    expect: () => const [PoemDetailError(NotFoundFailure())],
  );

  blocTest<PoemDetailBloc, PoemDetailState>(
    'stays on the poem being read when the collection updates',
    build: build,
    act: (bloc) async {
      bloc.add(const PoemDetailSubscriptionRequested('a'));
      source.add(const Ok(poems));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PoemDetailPageChanged(1));
      await Future<void>.delayed(Duration.zero);
      source.add(const Ok([morningTea, editedPaperBoats]));
    },
    expect: () => const [
      PoemDetailLoaded(poems: poems, index: 0),
      PoemDetailLoaded(poems: poems, index: 1),
      PoemDetailLoaded(poems: [morningTea, editedPaperBoats], index: 1),
    ],
  );

  blocTest<PoemDetailBloc, PoemDetailState>(
    'shares the current poem as text',
    build: build,
    seed: () => const PoemDetailLoaded(poems: poems, index: 0),
    act: (bloc) => bloc.add(const PoemDetailTextShareRequested()),
    verify: (_) => verify(
      () => shareService.shareText(
        '${morningTea.title}\n\n${morningTea.content}',
        subject: morningTea.title,
      ),
    ).called(1),
  );

  blocTest<PoemDetailBloc, PoemDetailState>(
    'shares a rendered image of the current poem',
    build: build,
    seed: () => const PoemDetailLoaded(poems: poems, index: 1),
    act: (bloc) => bloc.add(PoemDetailImageShareRequested(Uint8List(4))),
    verify: (_) =>
        verify(() => shareService.shareImage(any(), subject: paperBoats.title))
            .called(1),
  );

  blocTest<PoemDetailBloc, PoemDetailState>(
    'ignores share requests until a poem is loaded',
    build: build,
    act: (bloc) => bloc.add(const PoemDetailTextShareRequested()),
    verify: (_) => verifyZeroInteractions(shareService),
  );
}

const editedPaperBoats = PoemEntity(
  id: 'b',
  order: 2,
  title: 'Paper Boats',
  content: 'Edited',
);
