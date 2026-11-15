import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/domain/entities/activity_session.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_state.dart';
import 'package:doulapp/features/activities/presentation/pages/activity_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitySessionBloc
    extends MockBloc<ActivitySessionEvent, ActivitySessionState>
    implements ActivitySessionBloc {}

void main() {
  late MockActivitySessionBloc bloc;

  const activity = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración 4-7-8',
    description: 'Una pausa para bajar el ritmo.',
    contentText: 'Inhala en 4, sostén en 7 y exhala en 8.',
    modality: ActivityModality.practice,
    durationMinutes: 3,
  );

  final session = ActivitySession(
    id: 'sess-1',
    userId: 'usr-1',
    activityId: 'act-1',
    startedAt: DateTime.utc(2026, 11, 15, 10),
    status: ActivitySessionStatus.inProgress,
  );

  setUp(() {
    bloc = MockActivitySessionBloc();
    when(() => bloc.state).thenReturn(const ActivitySessionInitial());
  });

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage() {
    final router = GoRouter(
      initialLocation: '/session',
      routes: [
        GoRoute(
          path: '/session',
          builder: (_, _) => BlocProvider<ActivitySessionBloc>.value(
            value: bloc,
            child: const ActivitySessionPage(activity: activity),
          ),
        ),
        GoRoute(
          path: AppRoutes.moodCheckin,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Check-in')),
        ),
        GoRoute(
          path: AppRoutes.activities,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Microdescansos')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra cargando cuando el estado es starting', (tester) async {
    usePhone(tester);
    when(() => bloc.state).thenReturn(const ActivitySessionStarting(activity));

    await tester.pumpWidget(buildPage());

    expect(find.byKey(const Key('activity_session_loading')), findsOneWidget);
  });

  testWidgets('muestra el temporizador, el título y los pasos de la actividad', (
    tester,
  ) async {
    usePhone(tester);
    when(() => bloc.state).thenReturn(
      ActivitySessionActive(
        activity: activity,
        session: session,
        elapsedSeconds: 125,
      ),
    );

    await tester.pumpWidget(buildPage());

    expect(find.text('Respiración 4-7-8'), findsOneWidget);
    expect(find.text('02:05'), findsOneWidget);
    expect(find.text('Inhala en 4, sostén en 7 y exhala en 8.'), findsOneWidget);
    expect(find.byKey(const Key('activity_session_finish_button')), findsOneWidget);
  });

  testWidgets('pulsar Finalizar pausa envía ActivitySessionFinished', (
    tester,
  ) async {
    usePhone(tester);
    when(() => bloc.state).thenReturn(
      ActivitySessionActive(
        activity: activity,
        session: session,
        elapsedSeconds: 60,
      ),
    );

    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const Key('activity_session_finish_button')));

    verify(() => bloc.add(const ActivitySessionFinished())).called(1);
  });

  testWidgets('cerrar abre confirmación y Salir por ahora envía ActivitySessionAbandoned', (
    tester,
  ) async {
    usePhone(tester);
    when(() => bloc.state).thenReturn(
      ActivitySessionActive(
        activity: activity,
        session: session,
        elapsedSeconds: 25,
      ),
    );

    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const Key('activity_session_close_button')));
    await tester.pumpAndSettle();

    expect(find.text('¿Quieres terminar tu pausa por ahora?'), findsOneWidget);
    expect(find.byKey(const Key('activity_session_confirm_exit_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('activity_session_confirm_exit_button')));

    verify(() => bloc.add(const ActivitySessionAbandoned())).called(1);
  });

  testWidgets('al completar muestra la pantalla de cierre cálido', (
    tester,
  ) async {
    usePhone(tester);
    when(() => bloc.state).thenReturn(
      ActivitySessionCompleted(
        activity: activity,
        session: session,
        elapsedSeconds: 180,
      ),
    );

    await tester.pumpWidget(buildPage());

    expect(find.text('¡Pausa completada!'), findsOneWidget);
    expect(find.textContaining('Te regalaste 3 min y 0 seg para ti'), findsOneWidget);
    expect(find.byKey(const Key('activity_session_checkin_button')), findsOneWidget);
    expect(find.byKey(const Key('activity_session_return_button')), findsOneWidget);
  });
}
