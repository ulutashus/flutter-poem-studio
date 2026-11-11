import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_state.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_sync_cubit.dart';
import 'package:poem_studio/features/poem/presentation/pages/poem_list_page.dart';
import 'package:poem_studio/features/poem/presentation/routes/poem_paths.dart';
import 'package:poem_studio/features/settings/presentation/bloc/text_scale_cubit.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockPoemListBloc extends MockBloc<PoemListEvent, PoemListState>
    implements PoemListBloc {}

class _MockTextScaleCubit extends MockCubit<double> implements TextScaleCubit {}

class _MockPoemSyncCubit extends MockCubit<SyncStatus>
    implements PoemSyncCubit {}

void main() {
  late _MockPoemListBloc bloc;
  late _MockPoemSyncCubit syncCubit;

  setUp(() {
    bloc = _MockPoemListBloc();
    syncCubit = _MockPoemSyncCubit();
    when(() => syncCubit.state).thenReturn(SyncStatus.idle);
    when(() => syncCubit.retry()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, PoemListState state) {
    when(() => bloc.state).thenReturn(state);
    final textScale = _MockTextScaleCubit();
    when(() => textScale.state).thenReturn(1);
    return tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<PoemListBloc>.value(value: bloc),
          BlocProvider<TextScaleCubit>.value(value: textScale),
          BlocProvider<PoemSyncCubit>.value(value: syncCubit),
        ],
        child: const PoemListPage(),
      ),
      routes: [
        GoRoute(
          path: PoemPaths.detail,
          builder: (_, state) => Text('detail ${state.pathParameters['id']}'),
        ),
      ],
    );
  }

  const loaded = PoemListState(
    status: PoemListStatus.success,
    poems: poems,
    visiblePoems: poems,
  );

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pump(tester, const PoemListState());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('lists poems with their numbers', (tester) async {
    await pump(tester, loaded);

    expect(find.text('Morning Tea'), findsOneWidget);
    expect(find.text('Paper Boats'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('tells the user when nothing matches', (tester) async {
    await pump(
      tester,
      const PoemListState(status: PoemListStatus.success, poems: poems),
    );

    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('shows a readable failure message', (tester) async {
    await pump(
      tester,
      const PoemListState(
        status: PoemListStatus.failure,
        failure: StorageFailure(),
      ),
    );

    expect(
      find.text('Could not read or write data on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('sends typed queries to the bloc and can clear them', (
    tester,
  ) async {
    await pump(tester, loaded);

    await tester.enterText(find.byType(TextField), 'boats');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear'));

    verify(() => bloc.add(const PoemListQueryChanged('boats'))).called(1);
    verify(() => bloc.add(const PoemListQueryChanged(''))).called(1);
  });

  testWidgets('opens the tapped poem', (tester) async {
    await pump(tester, loaded);

    await tester.tap(find.text('Paper Boats'));
    await tester.pumpAndSettle();

    expect(find.text('detail b'), findsOneWidget);
  });

  testWidgets('offers a retry after a failed sync', (tester) async {
    when(() => syncCubit.state).thenReturn(SyncStatus.failed);
    await pump(tester, loaded);

    await tester.tap(find.byIcon(Icons.cloud_off_outlined));

    verify(() => syncCubit.retry()).called(1);
  });
}
