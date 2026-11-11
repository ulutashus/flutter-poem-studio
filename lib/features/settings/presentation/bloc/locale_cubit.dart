import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/settings/domain/repositories/settings_repository.dart';

/// Emits the active locale: the saved choice, else the device language, else the first supported one.
@injectable
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._repository, @Named('deviceLocale') Locale deviceLocale)
    : super(resolve(deviceLocale));

  final SettingsRepository _repository;

  static Locale resolve(Locale device) {
    const supported = AppLocalizations.supportedLocales;
    return supported.firstWhere(
      (l) => l.languageCode == device.languageCode,
      orElse: () => supported.first,
    );
  }

  Future<void> load() async {
    final result = await _repository.getLanguageCode();
    if (isClosed || result is! Ok<String?>) return;
    final locale = AppLocalizations.supportedLocales
        .where((l) => l.languageCode == result.data)
        .firstOrNull;
    if (locale != null) emit(locale);
  }

  /// Updates the UI first and rolls back if saving fails.
  Future<void> setLocale(Locale locale) async {
    final previous = state;
    emit(locale);
    final result = await _repository.setLanguageCode(locale.languageCode);
    if (result is Err && !isClosed && state == locale) emit(previous);
  }
}
