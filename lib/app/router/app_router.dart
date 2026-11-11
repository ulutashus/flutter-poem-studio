import 'package:go_router/go_router.dart';
import 'package:poem_studio/features/poem/presentation/routes/poem_paths.dart';
import 'package:poem_studio/features/poem/presentation/routes/poem_routes.dart';

/// Assembles the feature route modules; each module resolves its own blocs.
GoRouter createAppRouter() {
  return GoRouter(initialLocation: PoemPaths.list, routes: [...poemRoutes()]);
}
