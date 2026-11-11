import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:poem_studio/app/app.dart';
import 'package:poem_studio/app/app_bloc_observer.dart';
import 'package:poem_studio/app/di/injection_container.dart';
import 'package:poem_studio/core/logging/app_logger.dart';

/// Wires global error handling and dependencies before the first frame.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  final logger = getIt<AppLogger>();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logger.error(
      'Flutter framework error',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error('Uncaught platform error', error, stackTrace);
    return true;
  };
  Bloc.observer = AppBlocObserver(logger);

  runApp(const App());
}
