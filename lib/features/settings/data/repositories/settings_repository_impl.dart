import 'package:injectable/injectable.dart';
import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/logging/app_logger.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs, this._logger);

  static const _languageKey = 'language_code';
  static const _textScaleKey = 'text_scale';

  final SharedPreferences _prefs;
  final AppLogger _logger;

  @override
  Future<Result<String?>> getLanguageCode() =>
      _guard('Reading language', () async => _prefs.getString(_languageKey));

  @override
  Future<Result<void>> setLanguageCode(String code) =>
      _write('Saving language', () => _prefs.setString(_languageKey, code));

  @override
  Future<Result<double?>> getTextScale() =>
      _guard('Reading text scale', () async => _prefs.getDouble(_textScaleKey));

  @override
  Future<Result<void>> setTextScale(double scale) =>
      _write('Saving text scale', () => _prefs.setDouble(_textScaleKey, scale));

  Future<Result<void>> _write(
    String operation,
    Future<bool> Function() action,
  ) async {
    final result = await _guard(operation, action);
    if (result case Ok(data: false)) {
      _logger.error(
        '$operation failed',
        StateError('SharedPreferences rejected the write'),
        StackTrace.current,
      );
      return const Err<void>(StorageFailure());
    }
    return switch (result) {
      Ok() => const Ok<void>(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  // A stored value of the wrong type surfaces as a TypeError, not an Exception.
  Future<Result<T>> _guard<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return Ok(await action());
    } on Exception catch (e, s) {
      _logger.error('$operation failed', e, s);
      return Err<T>(const StorageFailure());
    } on TypeError catch (e, s) {
      _logger.error('$operation failed', e, s);
      return Err<T>(const StorageFailure());
    }
  }
}
