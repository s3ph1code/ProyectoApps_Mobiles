import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/activities/data/datasources/activities_remote_datasource.dart';
import 'package:doulapp/features/activities/data/models/activity_model.dart';
import 'package:doulapp/features/activities/data/repositories/activities_repository_impl.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitiesRemoteDataSource extends Mock
    implements ActivitiesRemoteDataSource {}

void main() {
  late MockActivitiesRemoteDataSource dataSource;
  late ActivitiesRepositoryImpl repository;

  const activityModel = ActivityModel(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración diafragmática',
    description: 'Técnica de respiración.',
    modality: ActivityModality.practice,
    durationMinutes: 5,
  );

  setUp(() {
    dataSource = MockActivitiesRemoteDataSource();
    repository = ActivitiesRepositoryImpl(remoteDataSource: dataSource);
  });

  group('getSavedActivities', () {
    test('devuelve lista de actividades guardadas en Right', () async {
      when(
        () => dataSource.fetchSavedActivities(userId: 'usr-1'),
      ).thenAnswer((_) async => [activityModel]);

      final result = await repository.getSavedActivities(userId: 'usr-1');

      expect(result, const Right([activityModel]));
      verify(() => dataSource.fetchSavedActivities(userId: 'usr-1')).called(1);
    });

    test('devuelve NetworkFailure cuando la fuente lanza NetworkException', () async {
      when(
        () => dataSource.fetchSavedActivities(userId: 'usr-1'),
      ).thenThrow(const NetworkException('Sin conexión'));

      final result = await repository.getSavedActivities(userId: 'usr-1');

      expect(result, const Left(NetworkFailure()));
    });
  });

  group('saveActivity', () {
    test('guarda la actividad y devuelve Right(null)', () async {
      when(
        () => dataSource.insertSavedActivity(
          userId: 'usr-1',
          activityId: 'act-1',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.saveActivity(
        userId: 'usr-1',
        activityId: 'act-1',
      );

      expect(result, const Right(null));
      verify(
        () => dataSource.insertSavedActivity(
          userId: 'usr-1',
          activityId: 'act-1',
        ),
      ).called(1);
    });

    test('devuelve ServerFailure cuando la fuente lanza ServerException', () async {
      when(
        () => dataSource.insertSavedActivity(
          userId: 'usr-1',
          activityId: 'act-1',
        ),
      ).thenThrow(const ServerException('Error de base de datos'));

      final result = await repository.saveActivity(
        userId: 'usr-1',
        activityId: 'act-1',
      );

      expect(result, const Left(ServerFailure()));
    });
  });

  group('unsaveActivity', () {
    test('elimina la actividad guardada y devuelve Right(null)', () async {
      when(
        () => dataSource.deleteSavedActivity(
          userId: 'usr-1',
          activityId: 'act-1',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.unsaveActivity(
        userId: 'usr-1',
        activityId: 'act-1',
      );

      expect(result, const Right(null));
      verify(
        () => dataSource.deleteSavedActivity(
          userId: 'usr-1',
          activityId: 'act-1',
        ),
      ).called(1);
    });

    test('devuelve ServerFailure cuando la fuente lanza ServerException', () async {
      when(
        () => dataSource.deleteSavedActivity(
          userId: 'usr-1',
          activityId: 'act-1',
        ),
      ).thenThrow(const ServerException('Error de base de datos'));

      final result = await repository.unsaveActivity(
        userId: 'usr-1',
        activityId: 'act-1',
      );

      expect(result, const Left(ServerFailure()));
    });
  });
}
