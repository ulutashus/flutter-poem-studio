import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/entities/text_scale.dart';
import 'package:poem_studio/features/settings/domain/repositories/settings_repository.dart';

/// Persists the scale clamped to the supported range.
@injectable
class SetTextScaleUseCase {
  const SetTextScaleUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> call(double scale) =>
      _repository.setTextScale(TextScale.clamp(scale));
}
