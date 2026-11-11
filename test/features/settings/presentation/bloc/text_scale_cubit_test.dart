import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/entities/text_scale.dart';
import 'package:poem_studio/features/settings/domain/usecases/get_text_scale_usecase.dart';
import 'package:poem_studio/features/settings/domain/usecases/set_text_scale_usecase.dart';
import 'package:poem_studio/features/settings/presentation/bloc/text_scale_cubit.dart';

class _MockGet extends Mock implements GetTextScaleUseCase {}

class _MockSet extends Mock implements SetTextScaleUseCase {}

void main() {
  late _MockGet get;
  late _MockSet set;

  setUp(() {
    get = _MockGet();
    set = _MockSet();
    when(() => set(any())).thenAnswer((_) async => const Ok(null));
  });

  TextScaleCubit build() => TextScaleCubit(get, set);

  blocTest<TextScaleCubit, double>(
    'load emits the saved scale',
    setUp: () => when(() => get()).thenAnswer((_) async => const Ok(1.4)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [1.4],
  );

  blocTest<TextScaleCubit, double>(
    'load keeps the default when reading fails',
    setUp: () =>
        when(() => get()).thenAnswer((_) async => const Err(StorageFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => <double>[],
  );

  blocTest<TextScaleCubit, double>(
    'setScale emits and persists through the use case',
    build: build,
    act: (cubit) => cubit.setScale(1.4),
    expect: () => [1.4],
    verify: (_) => verify(() => set(1.4)).called(1),
  );

  blocTest<TextScaleCubit, double>(
    'setScale rolls back when saving fails',
    setUp: () =>
        when(() => set(any()))
            .thenAnswer((_) async => const Err(StorageFailure())),
    build: build,
    act: (cubit) => cubit.setScale(1.5),
    expect: () => [1.5, TextScale.defaultValue],
  );

  blocTest<TextScaleCubit, double>(
    'reset returns to the default scale',
    build: build,
    seed: () => 1.5,
    act: (cubit) => cubit.reset(),
    expect: () => [TextScale.defaultValue],
  );
}
