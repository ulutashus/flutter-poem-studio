import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/entities/text_scale.dart';
import 'package:poem_studio/features/settings/domain/repositories/settings_repository.dart';

/// Returns the saved scale clamped to the supported range, or the default when none is saved.
@injectable
class GetTextScaleUseCase {
  const GetTextScaleUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Result<double>> call() async {
    return switch (await _repository.getTextScale()) {
      Err(:final failure) => Err(failure),
      Ok(:final data) => Ok(
        data == null ? TextScale.defaultValue : TextScale.clamp(data),
      ),
    };
  }
}
