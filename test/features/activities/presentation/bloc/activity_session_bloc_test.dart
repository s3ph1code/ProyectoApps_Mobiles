import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/domain/entities/activity_session.dart';
import 'package:doulapp/features/activities/domain/usecases/abandon_activity_session.dart';
import 'package:doulapp/features/activities/domain/usecases/finish_activity_session.dart';
import 'package:doulapp/features/activities/domain/usecases/start_activity_session.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_state.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}
class MockStartActivitySession extends Mock implements StartActivitySession {}
class MockFinishActivitySession extends Mock implements FinishActivitySession {}
class MockAbandonActivitySession extends Mock implements AbandonActivitySession {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockStartActivitySession startActivitySession;
  late MockFinishActivitySession finishActivitySession;
  late MockAbandonActivitySession abandonActivitySession;

  const activity = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración 4-7-8',
    description: 'Pausa breve',
    modality: ActivityModality.practice,
    durationMinutes: 3,
  );

  const user = AuthUser(id: 'usr-1', email: 'faiber@icesi.edu.co');

  final session = ActivitySession(
    id: 'sess-1',
    userId: 'usr-1',
    activityId: 'act-1',
    startedAt: DateTime.utc(2026, 11, 15, 10),
    status: ActivitySessionStatus.inProgress,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const StartActivitySessionParams(userId: 'u', activityId: 'a'),
    );
    registerFallbackValue(
      const FinishActivitySessionParams(sessionId: 's', elapsedSeconds: 0),
    );
    registerFallbackValue(
      const AbandonActivitySessionParams(sessionId: 's', elapsedSeconds: 0),
    );
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    startActivitySession = MockStartActivitySession();
    finishActivitySession = MockFinishActivitySession();
    abandonActivitySession = MockAbandonActivitySession();
  });

  ActivitySessionBloc buildBloc({Stream<int> Function()? ticker}) {
    return ActivitySessionBloc(
      getCurrentUser: getCurrentUser,
      startActivitySession: startActivitySession,
      finishActivitySession: finishActivitySession,
      abandonActivitySession: abandonActivitySession,
      ticker: ticker ?? (() => const Stream<int>.empty()),
    );
  }

  test('estado inicial es ActivitySessionInitial', () {
    expect(buildBloc().state, const ActivitySessionInitial());
  });

  blocTest<ActivitySessionBloc, ActivitySessionState>(
    'inicia sesión exitosamente y pasa a estado activo',
    build: () {
      when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
      when(() => startActivitySession(any())).thenAnswer((_) async => Right(session));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const ActivitySessionStarted(activity)),
    expect: () => [
      const ActivitySessionStarting(activity),
      ActivitySessionActive(
        activity: activity,
        session: session,
        elapsedSeconds: 0,
      ),
    ],
  );

  blocTest<ActivitySessionBloc, ActivitySessionState>(
    'si falla el guardado de la sesión, permite continuar con aviso claro',
    build: () {
      when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
      when(() => startActivitySession(any())).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const ActivitySessionStarted(activity)),
    expect: () => [
      const ActivitySessionStarting(activity),
      const ActivitySessionActive(
        activity: activity,
        session: null,
        elapsedSeconds: 0,
        sessionWarning:
            'No pudimos registrar tu sesión en la nube, pero puedes continuar tu pausa con calma.',
      ),
    ],
  );

  blocTest<ActivitySessionBloc, ActivitySessionState>(
    'actualiza los segundos transcurridos con ActivitySessionTicked',
    build: () => buildBloc(),
    seed: () => ActivitySessionActive(
      activity: activity,
      session: session,
      elapsedSeconds: 0,
    ),
    act: (bloc) => bloc.add(const ActivitySessionTicked(5)),
    expect: () => [
      ActivitySessionActive(
        activity: activity,
        session: session,
        elapsedSeconds: 5,
      ),
    ],
  );

  blocTest<ActivitySessionBloc, ActivitySessionState>(
    'finaliza la sesión marcándola como completada y guardando el tiempo',
    build: () {
      when(() => finishActivitySession(any())).thenAnswer((_) async => Right(session));
      return buildBloc();
    },
    seed: () => ActivitySessionActive(
      activity: activity,
      session: session,
      elapsedSeconds: 120,
    ),
    act: (bloc) => bloc.add(const ActivitySessionFinished()),
    expect: () => [
      ActivitySessionCompleted(
        activity: activity,
        session: session,
        elapsedSeconds: 120,
      ),
    ],
    verify: (_) {
      verify(
        () => finishActivitySession(
          const FinishActivitySessionParams(sessionId: 'sess-1', elapsedSeconds: 120),
        ),
      ).called(1);
    },
  );

  blocTest<ActivitySessionBloc, ActivitySessionState>(
    'abandonar la sesión la marca como abandonada sin culpa',
    build: () {
      when(() => abandonActivitySession(any())).thenAnswer((_) async => Right(session));
      return buildBloc();
    },
    seed: () => ActivitySessionActive(
      activity: activity,
      session: session,
      elapsedSeconds: 30,
    ),
    act: (bloc) => bloc.add(const ActivitySessionAbandoned()),
    expect: () => [
      const ActivitySessionAbandonedState(
        activity: activity,
        elapsedSeconds: 30,
      ),
    ],
    verify: (_) {
      verify(
        () => abandonActivitySession(
          const AbandonActivitySessionParams(sessionId: 'sess-1', elapsedSeconds: 30),
        ),
      ).called(1);
    },
  );
}
