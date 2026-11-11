import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/repositories/settings_repository.dart';
import 'package:poem_studio/features/settings/presentation/bloc/locale_cubit.dart';

class _MockRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockRepository repository;

  const supported = AppLocalizations.supportedLocales;
  const other = Locale('tr');

  setUp(() {
    repository = _MockRepository();
    when(() => repository.setLanguageCode(any()))
        .thenAnswer((_) async => const Ok(null));
  });

  LocaleCubit build({Locale device = const Locale('xx')}) =>
      LocaleCubit(repository, device);

  test('falls back to the first supported locale for an unknown device', () {
    expect(build().state, supported.first);
  });

  test('uses the device language when supported', () {
    expect(build(device: Locale(other.languageCode)).state, other);
  });

  blocTest<LocaleCubit, Locale>(
    'load restores the saved language',
    setUp: () =>
        when(() => repository.getLanguageCode())
            .thenAnswer((_) async => Ok<String?>(other.languageCode)),
    build: () => build(device: supported.first),
    act: (cubit) => cubit.load(),
    expect: () => [other],
  );

  blocTest<LocaleCubit, Locale>(
    'load ignores an unsupported language',
    setUp: () =>
        when(() => repository.getLanguageCode())
            .thenAnswer((_) async => const Ok('xx')),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => <Locale>[],
  );

  blocTest<LocaleCubit, Locale>(
    'load ignores a read failure',
    setUp: () =>
        when(() => repository.getLanguageCode())
            .thenAnswer((_) async => const Err(StorageFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => <Locale>[],
  );

  blocTest<LocaleCubit, Locale>(
    'setLocale emits and persists the choice',
    build: () => build(device: supported.first),
    seed: () => const Locale('zz'),
    act: (cubit) => cubit.setLocale(other),
    expect: () => [other],
    verify: (_) =>
        verify(() => repository.setLanguageCode(other.languageCode)).called(1),
  );

  blocTest<LocaleCubit, Locale>(
    'setLocale rolls back when saving fails',
    setUp: () =>
        when(() => repository.setLanguageCode(any()))
            .thenAnswer((_) async => const Err(StorageFailure())),
    build: build,
    seed: () => const Locale('zz'),
    act: (cubit) => cubit.setLocale(other),
    expect: () => [other, const Locale('zz')],
  );
}
