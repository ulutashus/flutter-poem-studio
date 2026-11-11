import 'package:go_router/go_router.dart';

import 'package:poem_studio/core/bloc/provide_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_event.dart';
import 'package:poem_studio/features/poem/presentation/pages/poem_detail_page.dart';
import 'package:poem_studio/features/poem/presentation/pages/poem_edit_page.dart';
import 'package:poem_studio/features/poem/presentation/pages/poem_list_page.dart';
import 'package:poem_studio/features/poem/presentation/routes/poem_paths.dart';

List<RouteBase> poemRoutes() => [
  GoRoute(
    path: PoemPaths.list,
    builder: (context, state) => provideBloc<PoemListBloc>(
      init: (bloc) => bloc.add(const PoemListSubscriptionRequested()),
      child: const PoemListPage(),
    ),
  ),
  GoRoute(
    path: PoemPaths.detail,
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: provideBloc<PoemDetailBloc>(
        init: (bloc) => bloc.add(
          PoemDetailSubscriptionRequested(state.pathParameters['id']!),
        ),
        child: const PoemDetailPage(),
      ),
    ),
  ),
  GoRoute(
    path: PoemPaths.edit,
    builder: (context, state) => provideBloc<PoemEditBloc>(
      init: (bloc) => bloc.add(PoemEditStarted(state.pathParameters['id']!)),
      child: const PoemEditPage(),
    ),
  ),
];
