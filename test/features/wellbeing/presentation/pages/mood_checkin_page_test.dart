import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/wellbeing/domain/entities/mood_checkin.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_checkin_bloc.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_checkin_event.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_checkin_state.dart';
import 'package:doulapp/features/wellbeing/presentation/pages/mood_checkin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockMoodCheckinBloc extends MockBloc<MoodCheckinEvent, MoodCheckinState>
    implements MoodCheckinBloc {}

void main() {
  late MockMoodCheckinBloc bloc;

  setUpAll(
    () => registerFallbackValue(const MoodCheckinSubmitted(moodScore: 1)),
  );
  setUp(() {
    bloc = MockMoodCheckinBloc();
    when(() => bloc.state).thenReturn(const MoodCheckinInitial());
  });

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Arranca en el check-in con Inicio debajo, como cuando se llega desde la
  /// tarjeta "Mi bienestar".
  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.moodCheckin,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Inicio')),
        ),
        GoRoute(
          path: AppRoutes.moodCheckin,
          builder: (_, _) => BlocProvider<MoodCheckinBloc>.value(
            value: bloc,
            child: const MoodCheckinPage(),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra las 5 opciones de ánimo con su etiqueta', (t) async {
    useSmallPhone(t);
    await t.pumpWidget(buildPage());

    for (final label in ['Muy mal', 'Mal', 'Regular', 'Bien', 'Muy bien']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (var i = 1; i <= 5; i++) {
      expect(find.byKey(Key('mood_option_$i')), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('guarda el ánimo elegido y la nota', (t) async {
    useSmallPhone(t);
    await t.pumpWidget(buildPage());

    await t.tap(find.byKey(const Key('mood_option_4')));
    await t.enterText(find.byKey(const Key('mood_note_field')), 'Dormí algo');
    await t.tap(find.byKey(const Key('mood_save_button')));

    verify(
      () => bloc.add(
        const MoodCheckinSubmitted(moodScore: 4, note: 'Dormí algo'),
      ),
    ).called(1);
  });

  testWidgets('sin elegir ánimo envía null para que se indique qué falta', (
    t,
  ) async {
    useSmallPhone(t);
    await t.pumpWidget(buildPage());

    await t.tap(find.byKey(const Key('mood_save_button')));

    verify(
      () => bloc.add(const MoodCheckinSubmitted(moodScore: null, note: '')),
    ).called(1);
  });

  testWidgets('muestra el error y conserva lo escrito', (t) async {
    useSmallPhone(t);
    whenListen(
      bloc,
      Stream.value(const MoodCheckinFailure('No hay conexión.')),
      initialState: const MoodCheckinInitial(),
    );
    await t.pumpWidget(buildPage());
    await t.enterText(find.byKey(const Key('mood_note_field')), 'Mi nota');
    await t.tap(find.byKey(const Key('mood_option_2')));
    await t.pump();

    expect(find.byKey(const Key('mood_error')), findsOneWidget);
    expect(find.text('Mi nota'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('bloquea el guardado mientras guarda', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const MoodCheckinSaving());
    await t.pumpWidget(buildPage());

    await t.tap(find.byKey(const Key('mood_save_button')));

    verifyNever(() => bloc.add(any()));
  });

  testWidgets(
    'tras guardar muestra el acompañamiento y no hay metas ni rachas',
    (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(
        MoodCheckinSuccess(
          MoodCheckin(id: 'c', moodScore: 2, recordedAt: DateTime.utc(2026)),
        ),
      );
      await t.pumpWidget(buildPage());

      expect(find.byKey(const Key('mood_success_title')), findsOneWidget);
      expect(
        find.textContaining('no tienes que resolverlo hoy'),
        findsOneWidget,
      );
      expect(find.textContaining('racha'), findsNothing);
      expect(find.textContaining('meta'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('"Listo" vuelve a la pantalla anterior', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      MoodCheckinSuccess(
        MoodCheckin(id: 'c', moodScore: 5, recordedAt: DateTime.utc(2026)),
      ),
    );
    await t.pumpWidget(buildPage());

    await t.tap(find.byKey(const Key('mood_done_button')));
    await t.pumpAndSettle();

    expect(find.text('Pantalla Inicio'), findsOneWidget);
  });

  testWidgets('"Omitir" sale sin guardar', (t) async {
    useSmallPhone(t);
    await t.pumpWidget(buildPage());

    await t.tap(find.byKey(const Key('mood_skip_button')));
    await t.pumpAndSettle();

    expect(find.text('Pantalla Inicio'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });
}
