import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/domain/repositories/activities_repository.dart';
import 'package:doulapp/features/activities/domain/usecases/get_saved_activities.dart';
import 'package:doulapp/features/activities/domain/usecases/save_activity.dart';
import 'package:doulapp/features/activities/domain/usecases/unsave_activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitiesRepository extends Mock implements ActivitiesRepository {}

void main() {
  late MockActivitiesRepository repository;
  late GetSavedActivities getSavedActivities;
  late SaveActivity saveActivity;
  late UnsaveActivity unsaveActivity;

  const activity = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración consciente',
    description: 'Pausa para respirar.',
    modality: ActivityModality.practice,
    durationMinutes: 5,
  );

  setUp(() {
    repository = MockActivitiesRepository();
    getSavedActivities = GetSavedActivities(repository);
    saveActivity = SaveActivity(repository);
    unsaveActivity = UnsaveActivity(repository);
  });

  group('GetSavedActivities', () {
    test('devuelve lista de actividades guardadas cuando userId es válido', () async {
      when(
        () => repository.getSavedActivities(userId: 'usr-1'),
      ).thenAnswer((_) async => const Right([activity]));

      final result = await getSavedActivities(
        const GetSavedActivitiesParams(userId: 'usr-1'),
      );

      expect(result, const Right([activity]));
      verify(() => repository.getSavedActivities(userId: 'usr-1')).called(1);
    });

    test('retorna UnauthenticatedFailure si userId está vacío', () async {
      final result = await getSavedActivities(
        const GetSavedActivitiesParams(userId: '   '),
      );

      expect(result, const Left(UnauthenticatedFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('SaveActivity', () {
    test('guarda la actividad correctamente cuando los parámetros son válidos', () async {
      when(
        () => repository.saveActivity(userId: 'usr-1', activityId: 'act-1'),
      ).thenAnswer((_) async => const Right(null));

      final result = await saveActivity(
        const SaveActivityParams(userId: 'usr-1', activityId: 'act-1'),
      );

      expect(result, const Right(null));
      verify(
        () => repository.saveActivity(userId: 'usr-1', activityId: 'act-1'),
      ).called(1);
    });

    test('falla si userId o activityId están vacíos', () async {
      final res1 = await saveActivity(
        const SaveActivityParams(userId: '', activityId: 'act-1'),
      );
      final res2 = await saveActivity(
        const SaveActivityParams(userId: 'usr-1', activityId: ''),
      );

      expect(res1, const Left(UnauthenticatedFailure()));
      expect(res2, const Left(ActivityNotFoundFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('UnsaveActivity', () {
    test('elimina la actividad guardada cuando los parámetros son válidos', () async {
      when(
        () => repository.unsaveActivity(userId: 'usr-1', activityId: 'act-1'),
      ).thenAnswer((_) async => const Right(null));

      final result = await unsaveActivity(
        const UnsaveActivityParams(userId: 'usr-1', activityId: 'act-1'),
      );

      expect(result, const Right(null));
      verify(
        () => repository.unsaveActivity(userId: 'usr-1', activityId: 'act-1'),
      ).called(1);
    });

    test('falla si userId o activityId están vacíos', () async {
      final res1 = await unsaveActivity(
        const UnsaveActivityParams(userId: '', activityId: 'act-1'),
      );
      final res2 = await unsaveActivity(
        const UnsaveActivityParams(userId: 'usr-1', activityId: ''),
      );

      expect(res1, const Left(UnauthenticatedFailure()));
      expect(res2, const Left(ActivityNotFoundFailure()));
      verifyZeroInteractions(repository);
    });
  });
}
