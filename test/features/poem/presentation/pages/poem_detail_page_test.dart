import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_state.dart';
import 'package:poem_studio/features/poem/presentation/pages/poem_detail_page.dart';
import 'package:poem_studio/features/settings/presentation/bloc/text_scale_cubit.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockPoemDetailBloc extends MockBloc<PoemDetailEvent, PoemDetailState>
    implements PoemDetailBloc {}

class _MockTextScaleCubit extends MockCubit<double> implements TextScaleCubit {}

void main() {
  late _MockPoemDetailBloc bloc;

  setUp(() => bloc = _MockPoemDetailBloc());

  Future<void> pump(WidgetTester tester, PoemDetailState state) {
    when(() => bloc.state).thenReturn(state);
    final textScale = _MockTextScaleCubit();
    when(() => textScale.state).thenReturn(1);
    return tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<PoemDetailBloc>.value(value: bloc),
          BlocProvider<TextScaleCubit>.value(value: textScale),
        ],
        child: const PoemDetailPage(),
      ),
    );
  }

  testWidgets('shows the poem number, title and each verse', (tester) async {
    await pump(tester, const PoemDetailLoaded(poems: poems, index: 0));

    expect(find.text('Poem #1'), findsOneWidget);
    expect(find.text('Morning Tea'), findsOneWidget);
    expect(find.text('Steam climbs slowly from the cup,'), findsOneWidget);
    expect(find.text('the kettle hums its quiet tune.'), findsOneWidget);
  });

  testWidgets('pages forward with the Next button', (tester) async {
    await pump(tester, const PoemDetailLoaded(poems: poems, index: 0));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const PoemDetailPageChanged(1))).called(1);
  });

  testWidgets('disables Previous on the first poem', (tester) async {
    await pump(tester, const PoemDetailLoaded(poems: poems, index: 0));

    final previous = find.ancestor(
      of: find.text('Previous'),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(previous).onPressed, isNull);
  });

  testWidgets('explains a missing poem', (tester) async {
    await pump(tester, const PoemDetailError(NotFoundFailure()));

    expect(find.text('This poem could not be found.'), findsOneWidget);
  });
}
