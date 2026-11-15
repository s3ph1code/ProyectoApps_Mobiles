import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/wellbeing/domain/entities/need_option.dart';
import 'package:doulapp/features/wellbeing/domain/entities/recommendation.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/needs_bloc.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/needs_event.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/needs_state.dart';
import 'package:doulapp/features/wellbeing/presentation/pages/needs_selection_page.dart';
import 'package:doulapp/features/wellbeing/presentation/pages/recommendations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockNeedsBloc extends MockBloc<NeedsEvent, NeedsState>
    implements NeedsBloc {}

void main() {
  late MockNeedsBloc bloc;

  const options = [
    NeedOption(id: 'opt-1', code: 'cansancio', label: 'Estoy muy cansada'),
    NeedOption(id: 'opt-2', code: 'ansiedad', label: 'Me siento ansiosa'),
  ];
  const recommendations = [
    Recommendation(
      id: 'rec-1',
      message: 'Una pausa corta puede ayudarte a recargar un poco.',
      priority: 10,
      activityId: 'act-1',
      destinationCode: 'activities',
    ),
    Recommendation(
      id: 'rec-2',
      message: 'Contarte cómo te sientes también cuenta.',
      priority: 20,
      destinationCode: 'mood_checkin',
    ),
  ];

  setUpAll(() => registerFallbackValue(const NeedOptionsRequested()));
  setUp(() {
    bloc = MockNeedsBloc();
    when(() => bloc.state).thenReturn(const NeedsInitial());
  });

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Las dos pantallas comparten el BLoC, como en el router real.
  Widget buildApp({required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.activities,
          builder: (_, _) =>
              const Scaffold(body: Text('Pantalla Microdescansos')),
          routes: [
            GoRoute(
              path: ':activityId',
              // Con barra, como el destino real: así se puede volver.
              builder: (_, state) => Scaffold(
                appBar: AppBar(title: const Text('Microdescanso')),
                body: Text(
                  'Pantalla Detalle ${state.pathParameters['activityId']}',
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.moodCheckin,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Check-in')),
        ),
        GoRoute(
          path: AppRoutes.community,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Comunidad')),
        ),
        ShellRoute(
          builder: (_, _, child) =>
              BlocProvider<NeedsBloc>.value(value: bloc, child: child),
          routes: [
            GoRoute(
              path: AppRoutes.needs,
              builder: (_, _) => const NeedsSelectionPage(),
            ),
            GoRoute(
              path: AppRoutes.needsRecommendations,
              builder: (_, _) => const RecommendationsPage(),
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Widget buildSelection() => buildApp(initialLocation: AppRoutes.needs);
  Widget buildRecommendations() =>
      buildApp(initialLocation: AppRoutes.needsRecommendations);

  group('NeedsSelectionPage', () {
    testWidgets('mientras carga muestra el indicador', (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(const NeedsLoadingOptions());

      await t.pumpWidget(buildSelection());

      expect(find.byKey(const Key('needs_loading')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('muestra las opciones activas', (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(
        const NeedsOptionsReady(options: options, selectedIds: {}),
      );

      await t.pumpWidget(buildSelection());

      expect(find.byKey(const Key('needs_option_opt-1')), findsOneWidget);
      expect(find.byKey(const Key('needs_option_opt-2')), findsOneWidget);
      expect(find.text('Estoy muy cansada'), findsOneWidget);
      expect(find.text('Me siento ansiosa'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('sin selección el botón de continuar está deshabilitado', (
      t,
    ) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(
        const NeedsOptionsReady(options: options, selectedIds: {}),
      );

      await t.pumpWidget(buildSelection());

      final button = t.widget<ElevatedButton>(
        find.byKey(const Key('needs_continue_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('con una opción elegida se puede continuar', (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(
        const NeedsOptionsReady(options: options, selectedIds: {'opt-1'}),
      );

      await t.pumpWidget(buildSelection());
      await t.tap(find.byKey(const Key('needs_continue_button')));

      verify(() => bloc.add(const NeedsSubmitted())).called(1);
    });

    testWidgets('tocar una opción la manda al BLoC', (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(
        const NeedsOptionsReady(options: options, selectedIds: {}),
      );

      await t.pumpWidget(buildSelection());
      await t.tap(find.byKey(const Key('needs_option_opt-2')));

      verify(() => bloc.add(const NeedOptionToggled('opt-2'))).called(1);
    });

    testWidgets('un error muestra el mensaje y permite reintentar', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const NeedsFailure('No hay conexión.'));

      await t.pumpWidget(buildSelection());

      expect(find.text('No hay conexión.'), findsOneWidget);

      await t.tap(find.byKey(const Key('needs_retry_button')));
      await t.pump();

      verify(() => bloc.add(const NeedOptionsRequested())).called(1);
    });

    testWidgets('cuando llegan las recomendaciones abre su pantalla', (
      t,
    ) async {
      useSmallPhone(t);
      whenListen(
        bloc,
        Stream.value(const NeedsRecommendationsReady(recommendations)),
        initialState: const NeedsOptionsReady(
          options: options,
          selectedIds: {'opt-1'},
        ),
      );

      await t.pumpWidget(buildSelection());
      await t.pumpAndSettle();

      expect(find.byKey(const Key('recommendation_rec-1')), findsOneWidget);
    });

    testWidgets('muchas opciones largas no desbordan el teléfono', (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(
        NeedsOptionsReady(
          options: List.generate(
            8,
            (i) => NeedOption(
              id: 'opt-$i',
              code: 'code-$i',
              label: 'Una necesidad descrita con muchas palabras número $i',
            ),
          ),
          selectedIds: const {},
        ),
      );

      await t.pumpWidget(buildSelection());

      expect(t.takeException(), isNull);
    });
  });

  group('RecommendationsPage', () {
    testWidgets('muestra las recomendaciones en el orden recibido', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const NeedsRecommendationsReady(recommendations));

      await t.pumpWidget(buildRecommendations());

      expect(find.byKey(const Key('recommendation_rec-1')), findsOneWidget);
      expect(find.byKey(const Key('recommendation_rec-2')), findsOneWidget);
      expect(
        find.text('Una pausa corta puede ayudarte a recargar un poco.'),
        findsOneWidget,
      );

      final primera = t.getTopLeft(
        find.byKey(const Key('recommendation_rec-1')),
      );
      final segunda = t.getTopLeft(
        find.byKey(const Key('recommendation_rec-2')),
      );
      expect(primera.dy, lessThan(segunda.dy));
      expect(t.takeException(), isNull);
    });

    testWidgets('el encabezado acompaña sin culpar', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const NeedsRecommendationsReady(recommendations));

      await t.pumpWidget(buildRecommendations());

      final texto = t
          .widget<Text>(find.byKey(const Key('recommendations_intro')))
          .data!;
      expect(texto, isNotEmpty);
      for (final culpa in ['deberías', 'debes', 'tienes que', 'fallaste']) {
        expect(texto.toLowerCase(), isNot(contains(culpa)), reason: culpa);
      }
    });

    testWidgets('sin recomendaciones muestra un mensaje de respaldo', (
      t,
    ) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const NeedsRecommendationsReady([]));

      await t.pumpWidget(buildRecommendations());

      expect(
        find.byKey(const Key('recommendations_fallback')),
        findsOneWidget,
      );
      expect(
        t
            .widget<Text>(
              find.byKey(const Key('recommendations_fallback_message')),
            )
            .data,
        isNotEmpty,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('un error muestra el mensaje', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const NeedsFailure('El servicio no respondió.'));

      await t.pumpWidget(buildRecommendations());

      expect(find.text('El servicio no respondió.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('destinos de una recomendación', () {
    /// Pinta las recomendaciones con una sola [recommendation] y la toca.
    Future<void> tapOn(WidgetTester t, Recommendation recommendation) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(NeedsRecommendationsReady([recommendation]));

      await t.pumpWidget(buildRecommendations());
      await t.tap(find.byKey(Key('recommendation_${recommendation.id}')));
      await t.pumpAndSettle();
    }

    testWidgets('con activity_id abre el detalle de esa actividad', (t) async {
      await tapOn(
        t,
        const Recommendation(
          id: 'rec-1',
          message: 'Respira conmigo.',
          priority: 10,
          activityId: 'act-1',
          destinationCode: 'activities',
        ),
      );

      expect(find.text('Pantalla Detalle act-1'), findsOneWidget);
    });

    testWidgets('puedo volver a las recomendaciones desde el destino', (
      t,
    ) async {
      await tapOn(
        t,
        const Recommendation(
          id: 'rec-1',
          message: 'Respira conmigo.',
          priority: 10,
          activityId: 'act-1',
        ),
      );
      expect(find.text('Pantalla Detalle act-1'), findsOneWidget);

      await t.pageBack();
      await t.pumpAndSettle();

      expect(find.byKey(const Key('recommendation_rec-1')), findsOneWidget);
    });

    testWidgets('activities abre la lista de microdescansos', (t) async {
      await tapOn(
        t,
        const Recommendation(
          id: 'rec-2',
          message: 'Mira los microdescansos.',
          priority: 10,
          destinationCode: 'activities',
        ),
      );

      expect(find.text('Pantalla Microdescansos'), findsOneWidget);
    });

    testWidgets('mood_checkin abre el check-in de ánimo', (t) async {
      await tapOn(
        t,
        const Recommendation(
          id: 'rec-3',
          message: 'Contarte cómo te sientes también cuenta.',
          priority: 10,
          destinationCode: 'mood_checkin',
        ),
      );

      expect(find.text('Pantalla Check-in'), findsOneWidget);
    });

    testWidgets('community abre la comunidad', (t) async {
      await tapOn(
        t,
        const Recommendation(
          id: 'rec-4',
          message: 'Otras madres están viviendo algo parecido.',
          priority: 10,
          destinationCode: 'community',
        ),
      );

      expect(find.text('Pantalla Comunidad'), findsOneWidget);
    });

    testWidgets('sin destino la tarjeta no navega ni falla', (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(
        const NeedsRecommendationsReady([
          Recommendation(id: 'rec-5', message: 'Solo un mensaje.', priority: 10),
        ]),
      );

      await t.pumpWidget(buildRecommendations());
      await t.tap(find.byKey(const Key('recommendation_rec-5')));
      await t.pumpAndSettle();

      expect(find.byKey(const Key('recommendation_rec-5')), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
