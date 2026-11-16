import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_state.dart';
import 'package:doulapp/features/activities/presentation/pages/saved_activities_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockSavedActivitiesBloc
    extends MockBloc<SavedActivitiesEvent, SavedActivitiesState>
    implements SavedActivitiesBloc {}

void main() {
  late MockSavedActivitiesBloc bloc;

  const breathing = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración diafragmática',
    description: 'Pausa para respirar.',
    modality: ActivityModality.practice,
    durationMinutes: 3,
  );

  const walking = Activity(
    id: 'act-2',
    categoryId: 'cat-2',
    title: 'Caminata lenta',
    description: 'Paso a paso con calma.',
    modality: ActivityModality.practice,
    durationMinutes: 7,
  );

  setUpAll(() {
    registerFallbackValue(const SavedActivitiesRequested());
    registerFallbackValue(const ActivitySaveToggled(breathing));
  });

  setUp(() {
    bloc = MockSavedActivitiesBloc();
    when(() => bloc.state).thenReturn(const SavedActivitiesInitial());
  });

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.savedActivities,
      routes: [
        GoRoute(
          path: AppRoutes.activities,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Microdescansos')),
          routes: [
            GoRoute(
              path: 'saved',
              builder: (_, _) => BlocProvider<SavedActivitiesBloc>.value(
                value: bloc,
                child: const SavedActivitiesPage(),
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => Scaffold(
                body: Text('Detalle ${state.pathParameters['id']}'),
              ),
              routes: [
                GoRoute(
                  path: 'session',
                  builder: (_, state) => Scaffold(
                    body: Text('Sesion ${state.pathParameters['id']}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra indicador de carga mientras consulta guardadas', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const SavedActivitiesLoading());

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('saved_activities_loading')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('muestra mensaje amable si no hay actividades guardadas', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const SavedActivitiesLoaded(activities: [], savedIds: {}),
    );

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('saved_activities_empty')), findsOneWidget);
    expect(
      find.text('Aún no tienes actividades guardadas'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('saved_activities_explore_button')),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('muestra la lista de actividades guardadas con sus datos', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const SavedActivitiesLoaded(
        activities: [breathing, walking],
        savedIds: {'act-1', 'act-2'},
      ),
    );

    await t.pumpWidget(buildPage());

    expect(find.text('Respiración diafragmática'), findsOneWidget);
    expect(find.text('Caminata lenta'), findsOneWidget);
    expect(find.textContaining('3 min'), findsOneWidget);
    expect(find.textContaining('7 min'), findsOneWidget);
    expect(find.byKey(const Key('saved_activity_item_act-1')), findsOneWidget);
    expect(find.byKey(const Key('saved_activity_item_act-2')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('tocar el botón de guardado en la tarjeta pide alternarlo', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const SavedActivitiesLoaded(
        activities: [breathing],
        savedIds: {'act-1'},
      ),
    );

    await t.pumpWidget(buildPage());
    await t.tap(find.byKey(const Key('activity_save_act-1')));
    await t.pump();

    verify(() => bloc.add(const ActivitySaveToggled(breathing))).called(1);
  });

  testWidgets('tocar comenzar abre la pantalla de sesión', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const SavedActivitiesLoaded(
        activities: [breathing],
        savedIds: {'act-1'},
      ),
    );

    await t.pumpWidget(buildPage());
    await t.tap(find.byKey(const Key('saved_activity_start_act-1')));
    await t.pumpAndSettle();

    expect(find.text('Sesion act-1'), findsOneWidget);
  });

  testWidgets('un error muestra mensaje y permite reintentar', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const SavedActivitiesFailure('No hay conexión a internet.'),
    );

    await t.pumpWidget(buildPage());

    expect(find.text('No hay conexión a internet.'), findsOneWidget);
    await t.tap(find.byKey(const Key('saved_activities_retry_button')));
    await t.pump();

    verify(() => bloc.add(const SavedActivitiesRequested())).called(1);
  });

  testWidgets('un noticeMessage muestra un SnackBar informativo', (t) async {
    useSmallPhone(t);
    whenListen(
      bloc,
      Stream.fromIterable([
        const SavedActivitiesLoaded(
          activities: [breathing],
          savedIds: {'act-1'},
          noticeMessage: 'No pudimos quitar la actividad. Inténtalo de nuevo.',
        ),
      ]),
      initialState: const SavedActivitiesLoaded(
        activities: [breathing],
        savedIds: {'act-1'},
      ),
    );

    await t.pumpWidget(buildPage());
    await t.pump();

    expect(
      find.text('No pudimos quitar la actividad. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });
}
