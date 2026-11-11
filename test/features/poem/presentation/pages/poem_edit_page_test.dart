import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_state.dart';
import 'package:poem_studio/features/poem/presentation/pages/poem_edit_page.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockPoemEditBloc extends MockBloc<PoemEditEvent, PoemEditState>
    implements PoemEditBloc {}

void main() {
  late _MockPoemEditBloc bloc;

  setUp(() => bloc = _MockPoemEditBloc());

  /// Opens the editor from a launcher page so popping has somewhere to go.
  Future<void> pump(WidgetTester tester) async {
    whenListen(
      bloc,
      const Stream<PoemEditState>.empty(),
      initialState: const PoemEditReady(poem: morningTea),
    );
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => context.push('/edit'),
          child: const Text('open'),
        ),
      ),
      routes: [
        GoRoute(
          path: '/edit',
          builder: (_, _) => BlocProvider<PoemEditBloc>.value(
            value: bloc,
            child: const PoemEditPage(),
          ),
        ),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.widgetWithText(TextButton, 'Save');

  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('pre-fills the form from the loaded poem', (tester) async {
    await pump(tester);

    expect(find.text(morningTea.title), findsOneWidget);
    expect(find.text(morningTea.content), findsOneWidget);
  });

  testWidgets('disables saving until something changes', (tester) async {
    await pump(tester);

    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);
  });

  testWidgets('disables saving while the title is blank', (tester) async {
    await pump(tester);

    await tester.enterText(field('Title'), '   ');
    await tester.pump();

    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);
  });

  testWidgets('submits the current text', (tester) async {
    await pump(tester);

    await tester.enterText(field('Title'), 'New title');
    await tester.pump();
    await tester.tap(saveButton());

    verify(
      () => bloc.add(
        PoemEditSaveRequested(title: 'New title', content: morningTea.content),
      ),
    ).called(1);
  });

  testWidgets('asks before discarding unsaved changes', (tester) async {
    await pump(tester);

    await tester.enterText(field('Title'), 'Changed');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Save your changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('leaves without asking when nothing changed', (tester) async {
    await pump(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });
}
