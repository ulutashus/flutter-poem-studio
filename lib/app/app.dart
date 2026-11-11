import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:poem_studio/app/router/app_router.dart';
import 'package:poem_studio/core/bloc/provide_bloc.dart';
import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/core/theme/app_theme.dart';
import 'package:poem_studio/core/widgets/app_scroll_behavior.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_sync_cubit.dart';
import 'package:poem_studio/features/settings/settings.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        provideBloc<TextScaleCubit>(init: (c) => c.load()),
        provideBloc<LocaleCubit>(init: (c) => c.load()),
        provideBloc<PoemSyncCubit>(init: (c) => c.start()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) => MaterialApp.router(
          locale: locale,
          onGenerateTitle: (context) => context.l10n.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          scrollBehavior: const AppScrollBehavior(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
