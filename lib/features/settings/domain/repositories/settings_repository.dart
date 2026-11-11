import 'package:poem_studio/core/result/result.dart';

abstract interface class SettingsRepository {
  Future<Result<String?>> getLanguageCode();

  Future<Result<void>> setLanguageCode(String code);

  Future<Result<double?>> getTextScale();

  Future<Result<void>> setTextScale(double scale);
}
