import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/entities/text_scale.dart';
import 'package:poem_studio/features/settings/domain/usecases/get_text_scale_usecase.dart';
import 'package:poem_studio/features/settings/domain/usecases/set_text_scale_usecase.dart';

@injectable
class TextScaleCubit extends Cubit<double> {
  TextScaleCubit(this._getTextScale, this._setTextScale)
    : super(TextScale.defaultValue);

  final GetTextScaleUseCase _getTextScale;
  final SetTextScaleUseCase _setTextScale;

  Future<void> load() async {
    final result = await _getTextScale();
    if (isClosed) return;
    if (result case Ok(:final data)) emit(data);
  }

  /// Updates the UI first so the slider stays responsive, and rolls back if saving fails.
  Future<void> setScale(double scale) async {
    final previous = state;
    emit(scale);
    final result = await _setTextScale(scale);
    if (result is Err && !isClosed && state == scale) emit(previous);
  }

  Future<void> reset() => setScale(TextScale.defaultValue);
}
