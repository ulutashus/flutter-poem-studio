import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/entities/text_scale.dart';
import 'package:poem_studio/features/settings/domain/repositories/settings_repository.dart';
import 'package:poem_studio/features/settings/domain/usecases/get_text_scale_usecase.dart';
import 'package:poem_studio/features/settings/domain/usecases/set_text_scale_usecase.dart';

class _MockRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  group('GetTextScaleUseCase', () {
    test('returns the default when nothing is saved', () async {
      when(() => repository.getTextScale())
          .thenAnswer((_) async => const Ok<double?>(null));

      expect(
        await GetTextScaleUseCase(repository)(),
        const Ok<double>(TextScale.defaultValue),
      );
    });

    test('clamps an out-of-range saved value', () async {
      when(() => repository.getTextScale())
          .thenAnswer((_) async => const Ok<double?>(9));

      expect(
        await GetTextScaleUseCase(repository)(),
        const Ok<double>(TextScale.max),
      );
    });

    test('passes a failure through', () async {
      when(() => repository.getTextScale())
          .thenAnswer((_) async => const Err<double?>(StorageFailure()));

      expect(
        await GetTextScaleUseCase(repository)(),
        const Err<double>(StorageFailure()),
      );
    });
  });

  group('SetTextScaleUseCase', () {
    test('persists the clamped value', () async {
      when(() => repository.setTextScale(any()))
          .thenAnswer((_) async => const Ok(null));

      await SetTextScaleUseCase(repository)(0.1);

      verify(() => repository.setTextScale(TextScale.min)).called(1);
    });
  });
}
