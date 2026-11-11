import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poem_studio/app/di/injection_container.dart';
import 'package:poem_studio/features/poem/data/datasources/local/poem_database.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_sync_cubit.dart';
import 'package:poem_studio/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:poem_studio/features/settings/presentation/bloc/text_scale_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(getIt.reset);

  test('resolves every entry point of the dependency graph', () async {
    await configureDependencies();
    // The on-device database needs platform plugins; swap in an in-memory one.
    await getIt.unregister<PoemDatabase>();
    getIt.registerSingleton(
      PoemDatabase(NativeDatabase.memory()),
      dispose: (db) => db.close(),
    );

    expect(getIt<PoemRepository>(), isNotNull);
    expect(getIt<PoemListBloc>(), isNotNull);
    expect(getIt<PoemDetailBloc>(), isNotNull);
    expect(getIt<PoemEditBloc>(), isNotNull);
    expect(getIt<PoemSyncCubit>(), isNotNull);
    expect(getIt<TextScaleCubit>(), isNotNull);
    expect(getIt<LocaleCubit>(), isNotNull);
  });
}
