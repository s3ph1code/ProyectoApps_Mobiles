import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/activities/domain/entities/activity_session.dart';
import 'package:doulapp/features/activities/domain/repositories/activities_repository.dart';
import 'package:doulapp/features/activities/domain/usecases/abandon_activity_session.dart';
import 'package:doulapp/features/activities/domain/usecases/finish_activity_session.dart';
import 'package:doulapp/features/activities/domain/usecases/start_activity_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitiesRepository extends Mock implements ActivitiesRepository {}

void main() {
  late MockActivitiesRepository repository;
  late StartActivitySession startUseCase;
  late FinishActivitySession finishUseCase;
  late AbandonActivitySession abandonUseCase;

  final session = ActivitySession(
    id: 'sess-1',
    userId: 'usr-1',
    activityId: 'act-1',
    startedAt: DateTime.utc(2026, 11, 15, 10),
    status: ActivitySessionStatus.inProgress,
  );

  setUp(() {
    repository = MockActivitiesRepository();
    startUseCase = StartActivitySession(repository);
    finishUseCase = FinishActivitySession(repository);
    abandonUseCase = AbandonActivitySession(repository);
  });

  group('StartActivitySession', () {
    test('inicia sesión correctamente cuando los parámetros son válidos', () async {
      when(
        () => repository.startSession(userId: 'usr-1', activityId: 'act-1'),
      ).thenAnswer((_) async => Right(session));

      final result = await startUseCase(
        const StartActivitySessionParams(userId: 'usr-1', activityId: 'act-1'),
      );

      expect(result, Right(session));
      verify(
        () => repository.startSession(userId: 'usr-1', activityId: 'act-1'),
      ).called(1);
    });

    test('falla si userId o activityId están vacíos', () async {
      final res1 = await startUseCase(
        const StartActivitySessionParams(userId: '', activityId: 'act-1'),
      );
      final res2 = await startUseCase(
        const StartActivitySessionParams(userId: 'usr-1', activityId: ''),
      );

      expect(res1, const Left(InvalidSessionFailure()));
      expect(res2, const Left(InvalidSessionFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('FinishActivitySession', () {
    test('finaliza sesión correctamente con datos válidos', () async {
      final finishedSession = ActivitySession(
        id: 'sess-1',
        userId: 'usr-1',
        activityId: 'act-1',
        startedAt: DateTime.utc(2026, 11, 15, 10),
        completedAt: DateTime.utc(2026, 11, 15, 10, 5),
        status: ActivitySessionStatus.completed,
        elapsedSeconds: 300,
      );

      when(
        () => repository.finishSession(sessionId: 'sess-1', elapsedSeconds: 300),
      ).thenAnswer((_) async => Right(finishedSession));

      final result = await finishUseCase(
        const FinishActivitySessionParams(sessionId: 'sess-1', elapsedSeconds: 300),
      );

      expect(result, Right(finishedSession));
    });

    test('falla si sessionId está vacío o elapsedSeconds es negativo', () async {
      final res1 = await finishUseCase(
        const FinishActivitySessionParams(sessionId: '', elapsedSeconds: 300),
      );
      final res2 = await finishUseCase(
        const FinishActivitySessionParams(sessionId: 'sess-1', elapsedSeconds: -1),
      );

      expect(res1, const Left(InvalidSessionFailure()));
      expect(res2, const Left(InvalidSessionFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('AbandonActivitySession', () {
    test('abandona sesión correctamente', () async {
      final abandonedSession = ActivitySession(
        id: 'sess-1',
        userId: 'usr-1',
        activityId: 'act-1',
        startedAt: DateTime.utc(2026, 11, 15, 10),
        status: ActivitySessionStatus.abandoned,
        elapsedSeconds: 45,
      );

      when(
        () => repository.abandonSession(sessionId: 'sess-1', elapsedSeconds: 45),
      ).thenAnswer((_) async => Right(abandonedSession));

      final result = await abandonUseCase(
        const AbandonActivitySessionParams(sessionId: 'sess-1', elapsedSeconds: 45),
      );

      expect(result, Right(abandonedSession));
    });
  });
}
