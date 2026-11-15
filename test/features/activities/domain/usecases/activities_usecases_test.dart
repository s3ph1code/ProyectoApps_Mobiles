import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_category.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/domain/repositories/activities_repository.dart';
import 'package:doulapp/features/activities/domain/usecases/get_activities.dart';
import 'package:doulapp/features/activities/domain/usecases/get_activity_by_id.dart';
import 'package:doulapp/features/activities/domain/usecases/get_activity_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitiesRepository extends Mock implements ActivitiesRepository {}

void main() {
  late MockActivitiesRepository repository;

  const categories = [
    ActivityCategory(id: 'cat-1', name: 'Respiración', slug: 'respiracion'),
    ActivityCategory(id: 'cat-2', name: 'Descanso', slug: 'descanso'),
  ];
  const activities = [
    Activity(
      id: 'act-1',
      categoryId: 'cat-1',
      title: 'Respiración 4-7-8',
      description: 'Una pausa para bajar el ritmo.',
      modality: ActivityModality.practice,
      durationMinutes: 3,
    ),
  ];

  setUp(() => repository = MockActivitiesRepository());

  group('GetActivityCategories', () {
    test('devuelve las categorías del repositorio', () async {
      when(
        () => repository.getCategories(),
      ).thenAnswer((_) async => const Right(categories));

      final result = await GetActivityCategories(repository)(const NoParams());

      expect(result, const Right<Failure, List<ActivityCategory>>(categories));
    });

    test('propaga el fallo del repositorio', () async {
      when(
        () => repository.getCategories(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await GetActivityCategories(repository)(const NoParams());

      expect(
        result,
        const Left<Failure, List<ActivityCategory>>(NetworkFailure()),
      );
    });
  });

  group('GetActivities', () {
    setUp(() {
      when(
        () => repository.getActivities(categoryId: any(named: 'categoryId')),
      ).thenAnswer((_) async => const Right(activities));
    });

    test('sin categoría pide todas las actividades', () async {
      final result = await GetActivities(repository)(const GetActivitiesParams());

      expect(result, const Right<Failure, List<Activity>>(activities));
      verify(() => repository.getActivities(categoryId: null)).called(1);
    });

    test('con categoría filtra por esa categoría', () async {
      await GetActivities(repository)(
        const GetActivitiesParams(categoryId: 'cat-1'),
      );

      verify(() => repository.getActivities(categoryId: 'cat-1')).called(1);
    });

    test('una categoría en blanco se trata como «todas»', () async {
      await GetActivities(repository)(const GetActivitiesParams(categoryId: '  '));

      verify(() => repository.getActivities(categoryId: null)).called(1);
    });

    test('propaga el fallo del repositorio', () async {
      when(
        () => repository.getActivities(categoryId: any(named: 'categoryId')),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await GetActivities(repository)(const GetActivitiesParams());

      expect(result, const Left<Failure, List<Activity>>(ServerFailure()));
    });
  });

  group('GetActivityById', () {
    const detail = Activity(
      id: 'act-1',
      categoryId: 'cat-1',
      title: 'Respiración 4-7-8',
      description: 'Una pausa para bajar el ritmo.',
      modality: ActivityModality.practice,
      durationMinutes: 3,
      contentText: 'Inhala contando 4, sostén 7 y suelta en 8.',
      externalUrl: 'https://ejemplo.org/guia',
    );

    test('devuelve la actividad con sus pasos y su enlace', () async {
      when(
        () => repository.getActivityById(any()),
      ).thenAnswer((_) async => const Right(detail));

      final result = await GetActivityById(repository)(
        const GetActivityByIdParams(activityId: 'act-1'),
      );

      expect(result.getOrElse(() => throw 'sin actividad'), detail);
      verify(() => repository.getActivityById('act-1')).called(1);
    });

    test('recorta el id antes de consultar', () async {
      when(
        () => repository.getActivityById(any()),
      ).thenAnswer((_) async => const Right(detail));

      await GetActivityById(repository)(
        const GetActivityByIdParams(activityId: '  act-1  '),
      );

      verify(() => repository.getActivityById('act-1')).called(1);
    });

    test('un id vacío se trata como actividad inexistente', () async {
      final result = await GetActivityById(repository)(
        const GetActivityByIdParams(activityId: '   '),
      );

      expect(
        result.swap().getOrElse(() => const UnexpectedFailure()),
        const ActivityNotFoundFailure(),
      );
      verifyNever(() => repository.getActivityById(any()));
    });

    test('propaga que la actividad no existe', () async {
      when(
        () => repository.getActivityById(any()),
      ).thenAnswer((_) async => const Left(ActivityNotFoundFailure()));

      final result = await GetActivityById(repository)(
        const GetActivityByIdParams(activityId: 'act-9'),
      );

      expect(
        result.swap().getOrElse(() => const UnexpectedFailure()),
        const ActivityNotFoundFailure(),
      );
    });
  });
}
