import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:poem_studio/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  AssetBundle get assetBundle => rootBundle;

  @singleton
  AppConfig get appConfig => AppConfig.fromEnvironment();

  @Named('deviceLocale')
  Locale get deviceLocale => PlatformDispatcher.instance.locale;

  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
