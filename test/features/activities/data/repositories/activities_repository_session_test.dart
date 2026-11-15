import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/activities/data/datasources/activities_remote_datasource.dart';
import 'package:doulapp/features/activities/data/models/activity_session_model.dart';
import 'package:doulapp/features/activities/data/repositories/activities_repository_impl.dart';
import 'package:doulapp/features/activities/domain/entities/activity_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitiesRemoteDataSource extends Mock
    implements ActivitiesRemoteDataSource {}

void main() {
  late MockActivitiesRemoteDataSource dataSource;
  late ActivitiesRepositoryImpl repository;

  final model = ActivitySessionModel(
    id: 'sess-1',
    userId: 'usr-1',
    activityId: 'act-1',
    startedAt: DateTime.utc(2026, 11, 15, 10),
    status: ActivitySessionStatus.inProgress,
  );

  setUp(() {
    dataSource = MockActivitiesRemoteDataSource();
    repository = ActivitiesRepositoryImpl(remoteDataSource: dataSource);
  });

  test('startSession devuelve el modelo en Right', () async {
    when(
      () => dataSource.insertSession(userId: 'usr-1', activityId: 'act-1'),
    ).thenAnswer((_) async => model);

    final result = await repository.startSession(
      userId: 'usr-1',
      activityId: 'act-1',
    );

    expect(result, Right(model));
  });

  test('finishSession devuelve la sesión completada', () async {
    final completedModel = ActivitySessionModel(
      id: 'sess-1',
      userId: 'usr-1',
      activityId: 'act-1',
      startedAt: DateTime.utc(2026, 11, 15, 10),
      completedAt: DateTime.utc(2026, 11, 15, 10, 5),
      status: ActivitySessionStatus.completed,
      elapsedSeconds: 300,
    );

    when(
      () => dataSource.updateSessionStatus(
        sessionId: 'sess-1',
        status: 'completed',
        elapsedSeconds: 300,
        completedAt: any(named: 'completedAt'),
      ),
    ).thenAnswer((_) async => completedModel);

    final result = await repository.finishSession(
      sessionId: 'sess-1',
      elapsedSeconds: 300,
    );

    expect(result, Right(completedModel));
  });

  test('abandonSession devuelve la sesión abandonada', () async {
    final abandonedModel = ActivitySessionModel(
      id: 'sess-1',
      userId: 'usr-1',
      activityId: 'act-1',
      startedAt: DateTime.utc(2026, 11, 15, 10),
      status: ActivitySessionStatus.abandoned,
      elapsedSeconds: 20,
    );

    when(
      () => dataSource.updateSessionStatus(
        sessionId: 'sess-1',
        status: 'abandoned',
        elapsedSeconds: 20,
        completedAt: any(named: 'completedAt'),
      ),
    ).thenAnswer((_) async => abandonedModel);

    final result = await repository.abandonSession(
      sessionId: 'sess-1',
      elapsedSeconds: 20,
    );

    expect(result, Right(abandonedModel));
  });

  test('mapea excepciones de red y servidor a Failure', () async {
    when(
      () => dataSource.insertSession(userId: any(named: 'userId'), activityId: any(named: 'activityId')),
    ).thenThrow(const NetworkException('sin red'));

    final res1 = await repository.startSession(userId: 'u', activityId: 'a');
    expect(res1, const Left(NetworkFailure()));

    when(
      () => dataSource.insertSession(userId: any(named: 'userId'), activityId: any(named: 'activityId')),
    ).thenThrow(const ServerException('error servidor'));

    final res2 = await repository.startSession(userId: 'u', activityId: 'a');
    expect(res2, const Left(ServerFailure()));
  });
}
