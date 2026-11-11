import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_sync_cubit.dart';

class _MockRepository extends Mock implements PoemRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.syncPoems()).thenAnswer((_) async => const Ok(null));
    when(() => repository.watchSyncStatus()).thenAnswer(
      (_) => Stream.fromIterable([SyncStatus.syncing, SyncStatus.failed]),
    );
  });

  PoemSyncCubit build() => PoemSyncCubit(repository);

  blocTest<PoemSyncCubit, SyncStatus>(
    'start mirrors the repository status and runs a sync',
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [SyncStatus.syncing, SyncStatus.failed],
    verify: (_) => verify(() => repository.syncPoems()).called(1),
  );

  blocTest<PoemSyncCubit, SyncStatus>(
    'retry runs another sync even if the last one failed',
    setUp: () =>
        when(() => repository.syncPoems())
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: build,
    act: (cubit) => cubit.retry(),
    verify: (_) => verify(() => repository.syncPoems()).called(1),
  );
}
