import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/activities/data/datasources/activities_remote_datasource.dart';
import 'package:doulapp/features/activities/data/models/activity_category_model.dart';
import 'package:doulapp/features/activities/data/models/activity_model.dart';
import 'package:doulapp/features/activities/data/repositories/activities_repository_impl.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitiesDataSource extends Mock
    implements ActivitiesRemoteDataSource {}

void main() {
  late MockActivitiesDataSource dataSource;
  late ActivitiesRepositoryImpl repository;

  const category = ActivityCategoryModel(
    id: 'cat-1',
    name: 'Respiración',
    slug: 'respiracion',
  );
  const activity = ActivityModel(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración 4-7-8',
    description: 'Una pausa.',
    modality: ActivityModality.practice,
    durationMinutes: 3,
  );

  setUp(() {
    dataSource = MockActivitiesDataSource();
    repository = ActivitiesRepositoryImpl(remoteDataSource: dataSource);
  });

  final errorCases = <String, (Exception, Failure)>{
    'ServerException': (const ServerException('x'), const ServerFailure()),
    'NetworkException': (const NetworkException('x'), const NetworkFailure()),
    'UnauthenticatedException': (
      const UnauthenticatedException(),
      const UnauthenticatedFailure(),
    ),
  };

  group('getCategories', () {
    test('devuelve las categorías del datasource', () async {
      when(
        () => dataSource.fetchCategories(),
      ).thenAnswer((_) async => [category]);

      final result = await repository.getCategories();

      expect(result.getOrElse(() => []), [category]);
    });

    errorCases.forEach((name, pair) {
      test('mapea $name a su Failure', () async {
        when(() => dataSource.fetchCategories()).thenThrow(pair.$1);

        final result = await repository.getCategories();

        expect(result.swap().getOrElse(() => const UnexpectedFailure()), pair.$2);
      });
    });

    test('un error inesperado se vuelve UnexpectedFailure', () async {
      when(() => dataSource.fetchCategories()).thenThrow(StateError('boom'));

      final result = await repository.getCategories();

      expect(
        result.swap().getOrElse(() => const ServerFailure()),
        const UnexpectedFailure(),
      );
    });
  });

  group('getActivities', () {
    test('pasa la categoría tal cual al datasource', () async {
      when(
        () => dataSource.fetchActivities(categoryId: any(named: 'categoryId')),
      ).thenAnswer((_) async => [activity]);

      final result = await repository.getActivities(categoryId: 'cat-1');

      expect(result.getOrElse(() => []), [activity]);
      verify(() => dataSource.fetchActivities(categoryId: 'cat-1')).called(1);
    });

    test('sin categoría consulta todas', () async {
      when(
        () => dataSource.fetchActivities(categoryId: any(named: 'categoryId')),
      ).thenAnswer((_) async => [activity]);

      await repository.getActivities();

      verify(() => dataSource.fetchActivities(categoryId: null)).called(1);
    });

    errorCases.forEach((name, pair) {
      test('mapea $name a su Failure', () async {
        when(
          () =>
              dataSource.fetchActivities(categoryId: any(named: 'categoryId')),
        ).thenThrow(pair.$1);

        final result = await repository.getActivities();

        expect(result.swap().getOrElse(() => const UnexpectedFailure()), pair.$2);
      });
    });
  });

  group('getActivityById', () {
    test('devuelve la actividad del datasource', () async {
      when(
        () => dataSource.fetchActivityById(any()),
      ).thenAnswer((_) async => activity);

      final result = await repository.getActivityById('act-1');

      expect(result.getOrElse(() => throw 'sin actividad'), activity);
      verify(() => dataSource.fetchActivityById('act-1')).called(1);
    });

    test('NotFoundException se vuelve ActivityNotFoundFailure', () async {
      when(
        () => dataSource.fetchActivityById(any()),
      ).thenThrow(const NotFoundException());

      final result = await repository.getActivityById('act-9');

      expect(
        result.swap().getOrElse(() => const UnexpectedFailure()),
        const ActivityNotFoundFailure(),
      );
    });

    errorCases.forEach((name, pair) {
      test('mapea $name a su Failure', () async {
        when(() => dataSource.fetchActivityById(any())).thenThrow(pair.$1);

        final result = await repository.getActivityById('act-1');

        expect(result.swap().getOrElse(() => const UnexpectedFailure()), pair.$2);
      });
    });
  });
}
