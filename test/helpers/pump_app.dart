import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  /// Pumps [page] at `/` inside a localized, themed router app; [routes] add navigation targets.
  Future<GoRouter> pumpApp(
    Widget page, {
    List<RouteBase> routes = const [],
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => page),
        ...routes,
      ],
    );
    addTearDown(router.dispose);
    await pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    return router;
  }
}
