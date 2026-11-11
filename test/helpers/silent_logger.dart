import 'package:poem_studio/core/logging/app_logger.dart';

class SilentLogger implements AppLogger {
  final errors = <Object>[];

  @override
  void info(String message) {}

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void error(String message, Object error, StackTrace stackTrace) =>
      errors.add(error);
}
