import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/silent_logger.dart';

class _MockPrefs extends Mock implements SharedPreferences {}

void main() {
  late SilentLogger logger;

  setUp(() => logger = SilentLogger());

  Future<SettingsRepositoryImpl> realRepository(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return SettingsRepositoryImpl(
      await SharedPreferences.getInstance(),
      logger,
    );
  }

  test('round-trips the language code and text scale', () async {
    final repository = await realRepository({});

    expect(await repository.getLanguageCode(), const Ok<String?>(null));
    expect(await repository.setLanguageCode('tr'), const Ok<void>(null));
    expect(await repository.getLanguageCode(), const Ok<String?>('tr'));

    expect(await repository.setTextScale(1.4), const Ok<void>(null));
    expect(await repository.getTextScale(), const Ok<double?>(1.4));
  });

  test('maps a stored value of the wrong type to StorageFailure', () async {
    final repository = await realRepository({'text_scale': 'big'});

    expect(
      await repository.getTextScale(),
      const Err<double?>(StorageFailure()),
    );
    expect(logger.errors, hasLength(1));
  });

  test('maps a rejected write to StorageFailure', () async {
    final prefs = _MockPrefs();
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => false);
    final repository = SettingsRepositoryImpl(prefs, logger);

    expect(
      await repository.setLanguageCode('tr'),
      const Err<void>(StorageFailure()),
    );
    expect(logger.errors, hasLength(1));
  });

  test('maps a throwing write to StorageFailure', () async {
    final prefs = _MockPrefs();
    when(() => prefs.setDouble(any(), any())).thenThrow(Exception('disk'));
    final repository = SettingsRepositoryImpl(prefs, logger);

    expect(
      await repository.setTextScale(1.2),
      const Err<void>(StorageFailure()),
    );
  });
}
