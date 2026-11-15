import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_category.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/domain/usecases/get_activities.dart';
import 'package:doulapp/features/activities/domain/usecases/get_activity_categories.dart';
import 'package:doulapp/features/activities/presentation/bloc/activities_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/activities_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/activities_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetActivityCategories extends Mock
    implements GetActivityCategories {}

class MockGetActivities extends Mock implements GetActivities {}

void main() {
  late MockGetActivityCategories getCategories;
  late MockGetActivities getActivities;

  const categories = [
    ActivityCategory(id: 'cat-1', name: 'Respiración', slug: 'respiracion'),
    ActivityCategory(id: 'cat-2', name: 'Descanso', slug: 'descanso'),
  ];
  const breathing = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración 4-7-8',
    description: 'Una pausa.',
    modality: ActivityModality.practice,
    durationMinutes: 3,
  );
  const rest = Activity(
    id: 'act-2',
    categoryId: 'cat-2',
    title: 'Cinco minutos con los ojos cerrados',
    description: 'Solo parar un momento.',
    modality: ActivityModality.practice,
    durationMinutes: 5,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetActivitiesParams());
  });

  setUp(() {
    getCategories = MockGetActivityCategories();
    getActivities = MockGetActivities();
    when(
      () => getCategories(any()),
    ).thenAnswer((_) async => const Right(categories));
    when(
      () => getActivities(any()),
    ).thenAnswer((_) async => const Right([breathing, rest]));
  });

  ActivitiesBloc build() => ActivitiesBloc(
    getActivityCategories: getCategories,
    getActivities: getActivities,
  );

  blocTest<ActivitiesBloc, ActivitiesState>(
    'al abrir carga las categorías y todas las actividades publicadas',
    build: build,
    act: (b) => b.add(const ActivitiesRequested()),
    expect: () => [
      const ActivitiesLoading(),
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing, rest],
      ),
    ],
    verify: (_) =>
        verify(() => getActivities(const GetActivitiesParams())).called(1),
  );

  blocTest<ActivitiesBloc, ActivitiesState>(
    'elegir una categoría recarga solo esa, sin perder los filtros',
    build: () {
      when(() => getActivities(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetActivitiesParams;
        return Right(params.categoryId == null ? [breathing, rest] : [rest]);
      });
      return build();
    },
    act: (b) async {
      b.add(const ActivitiesRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityCategorySelected('cat-2'));
    },
    expect: () => [
      const ActivitiesLoading(),
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing, rest],
      ),
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing, rest],
        selectedCategoryId: 'cat-2',
        isLoadingActivities: true,
      ),
      const ActivitiesLoaded(
        categories: categories,
        activities: [rest],
        selectedCategoryId: 'cat-2',
      ),
    ],
    verify: (_) => verify(
      () => getActivities(const GetActivitiesParams(categoryId: 'cat-2')),
    ).called(1),
  );

  blocTest<ActivitiesBloc, ActivitiesState>(
    '«Todas» vuelve a pedir la lista completa',
    build: build,
    act: (b) async {
      b.add(const ActivitiesRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityCategorySelected('cat-1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityCategorySelected(null));
    },
    verify: (_) {
      verify(() => getActivities(const GetActivitiesParams())).called(2);
      verify(
        () => getActivities(const GetActivitiesParams(categoryId: 'cat-1')),
      ).called(1);
    },
  );

  blocTest<ActivitiesBloc, ActivitiesState>(
    'una categoría sin actividades deja la lista vacía, no un error',
    build: () {
      when(
        () => getActivities(any()),
      ).thenAnswer((_) async => const Right([]));
      return build();
    },
    act: (b) => b.add(const ActivitiesRequested()),
    expect: () => [
      const ActivitiesLoading(),
      const ActivitiesLoaded(categories: categories, activities: []),
    ],
  );

  blocTest<ActivitiesBloc, ActivitiesState>(
    'si fallan las categorías muestra el error',
    build: () {
      when(
        () => getCategories(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (b) => b.add(const ActivitiesRequested()),
    expect: () => [
      const ActivitiesLoading(),
      ActivitiesFailure(const NetworkFailure().message),
    ],
    verify: (_) => verifyNever(() => getActivities(any())),
  );

  blocTest<ActivitiesBloc, ActivitiesState>(
    'si fallan las actividades muestra el error y permite reintentar',
    build: () {
      var calls = 0;
      when(() => getActivities(any())).thenAnswer((_) async {
        calls++;
        return calls == 1
            ? const Left(ServerFailure())
            : const Right([breathing, rest]);
      });
      return build();
    },
    act: (b) async {
      b.add(const ActivitiesRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivitiesRequested());
    },
    expect: () => [
      const ActivitiesLoading(),
      ActivitiesFailure(const ServerFailure().message),
      const ActivitiesLoading(),
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing, rest],
      ),
    ],
  );

  blocTest<ActivitiesBloc, ActivitiesState>(
    'elegir categoría antes de que haya cargado no hace nada',
    build: build,
    act: (b) => b.add(const ActivityCategorySelected('cat-1')),
    expect: () => <ActivitiesState>[],
    verify: (_) => verifyNever(() => getActivities(any())),
  );
}
