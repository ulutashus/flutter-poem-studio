import 'dart:developer' as developer;

import 'package:injectable/injectable.dart';
import 'package:poem_studio/core/logging/app_logger.dart';

@LazySingleton(as: AppLogger)
class DeveloperLogger implements AppLogger {
  static const _name = 'poem_studio';

  @override
  void info(String message) => developer.log(message, name: _name, level: 800);

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
