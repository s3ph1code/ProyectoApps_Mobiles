import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/domain/usecases/get_saved_activities.dart';
import 'package:doulapp/features/activities/domain/usecases/save_activity.dart';
import 'package:doulapp/features/activities/domain/usecases/unsave_activity.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_state.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}
class MockGetSavedActivities extends Mock implements GetSavedActivities {}
class MockSaveActivity extends Mock implements SaveActivity {}
class MockUnsaveActivity extends Mock implements UnsaveActivity {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetSavedActivities getSavedActivities;
  late MockSaveActivity saveActivity;
  late MockUnsaveActivity unsaveActivity;
  late SavedActivitiesBloc bloc;

  const user = AuthUser(id: 'usr-1', email: 'madre@ejemplo.org');

  const activity1 = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración diafragmática',
    description: 'Pausa para respirar.',
    modality: ActivityModality.practice,
    durationMinutes: 5,
  );

  const activity2 = Activity(
    id: 'act-2',
    categoryId: 'cat-2',
    title: 'Escáner corporal',
    description: 'Atención al cuerpo.',
    modality: ActivityModality.read,
    durationMinutes: 6,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetSavedActivitiesParams(userId: 'u'));
    registerFallbackValue(const SaveActivityParams(userId: 'u', activityId: 'a'));
    registerFallbackValue(const UnsaveActivityParams(userId: 'u', activityId: 'a'));
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getSavedActivities = MockGetSavedActivities();
    saveActivity = MockSaveActivity();
    unsaveActivity = MockUnsaveActivity();

    bloc = SavedActivitiesBloc(
      getCurrentUser: getCurrentUser,
      getSavedActivities: getSavedActivities,
      saveActivity: saveActivity,
      unsaveActivity: unsaveActivity,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('el estado inicial es SavedActivitiesInitial', () {
    expect(bloc.state, const SavedActivitiesInitial());
  });

  group('SavedActivitiesRequested', () {
    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'emite [Loading, Loaded] cuando la consulta es exitosa',
      build: () {
        when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
        when(() => getSavedActivities(any())).thenAnswer((_) async => const Right([activity1]));
        return bloc;
      },
      act: (b) => b.add(const SavedActivitiesRequested()),
      expect: () => [
        const SavedActivitiesLoading(),
        const SavedActivitiesLoaded(
          activities: [activity1],
          savedIds: {'act-1'},
        ),
      ],
      verify: (_) {
        verify(() => getSavedActivities(const GetSavedActivitiesParams(userId: 'usr-1'))).called(1);
      },
    );

    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'emite [Loading, Failure] si no hay usuaria autenticada',
      build: () {
        when(() => getCurrentUser(any())).thenAnswer(
          (_) async => const Left(UnauthenticatedFailure()),
        );
        return bloc;
      },
      act: (b) => b.add(const SavedActivitiesRequested()),
      expect: () => [
        const SavedActivitiesLoading(),
        const SavedActivitiesFailure(
          'Inicia sesión para consultar tus actividades guardadas.',
        ),
      ],
      verify: (_) {
        verifyZeroInteractions(getSavedActivities);
      },
    );

    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'emite [Loading, Failure] si la consulta remota falla',
      build: () {
        when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
        when(() => getSavedActivities(any())).thenAnswer(
          (_) async => const Left(NetworkFailure()),
        );
        return bloc;
      },
      act: (b) => b.add(const SavedActivitiesRequested()),
      expect: () => [
        const SavedActivitiesLoading(),
        const SavedActivitiesFailure(
          'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.',
        ),
      ],
    );
  });

  group('ActivitySaveToggled', () {
    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'guarda optimísticamente una actividad no guardada y llama a SaveActivity',
      build: () {
        when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
        when(() => saveActivity(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const SavedActivitiesLoaded(
        activities: [activity1],
        savedIds: {'act-1'},
      ),
      act: (b) => b.add(const ActivitySaveToggled(activity2)),
      expect: () => [
        const SavedActivitiesLoaded(
          activities: [activity2, activity1],
          savedIds: {'act-1', 'act-2'},
          noticeMessage: null,
        ),
      ],
      verify: (_) {
        verify(
          () => saveActivity(
            const SaveActivityParams(userId: 'usr-1', activityId: 'act-2'),
          ),
        ).called(1);
      },
    );

    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'revierte el guardado optimista y muestra aviso si SaveActivity falla',
      build: () {
        when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
        when(() => saveActivity(any())).thenAnswer(
          (_) async => const Left(ServerFailure()),
        );
        return bloc;
      },
      seed: () => const SavedActivitiesLoaded(
        activities: [activity1],
        savedIds: {'act-1'},
      ),
      act: (b) => b.add(const ActivitySaveToggled(activity2)),
      expect: () => [
        // Optimista primero
        const SavedActivitiesLoaded(
          activities: [activity2, activity1],
          savedIds: {'act-1', 'act-2'},
          noticeMessage: null,
        ),
        // Reversión con aviso
        const SavedActivitiesLoaded(
          activities: [activity1],
          savedIds: {'act-1'},
          noticeMessage: 'No pudimos guardar la actividad. Inténtalo de nuevo.',
        ),
      ],
    );

    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'quita optimísticamente una actividad guardada y llama a UnsaveActivity',
      build: () {
        when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
        when(() => unsaveActivity(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const SavedActivitiesLoaded(
        activities: [activity1, activity2],
        savedIds: {'act-1', 'act-2'},
      ),
      act: (b) => b.add(const ActivitySaveToggled(activity1)),
      expect: () => [
        const SavedActivitiesLoaded(
          activities: [activity2],
          savedIds: {'act-2'},
          noticeMessage: null,
        ),
      ],
      verify: (_) {
        verify(
          () => unsaveActivity(
            const UnsaveActivityParams(userId: 'usr-1', activityId: 'act-1'),
          ),
        ).called(1);
      },
    );

    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'revierte la eliminación optimista y muestra aviso si UnsaveActivity falla',
      build: () {
        when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(user));
        when(() => unsaveActivity(any())).thenAnswer(
          (_) async => const Left(NetworkFailure()),
        );
        return bloc;
      },
      seed: () => const SavedActivitiesLoaded(
        activities: [activity1, activity2],
        savedIds: {'act-1', 'act-2'},
      ),
      act: (b) => b.add(const ActivitySaveToggled(activity1)),
      expect: () => [
        // Optimista primero
        const SavedActivitiesLoaded(
          activities: [activity2],
          savedIds: {'act-2'},
          noticeMessage: null,
        ),
        // Reversión con aviso
        const SavedActivitiesLoaded(
          activities: [activity1, activity2],
          savedIds: {'act-1', 'act-2'},
          noticeMessage: 'No pudimos quitar la actividad. Inténtalo de nuevo.',
        ),
      ],
    );
  });

  group('SavedActivitiesNoticeDismissed', () {
    blocTest<SavedActivitiesBloc, SavedActivitiesState>(
      'limpia noticeMessage cuando se descarta',
      build: () => bloc,
      seed: () => const SavedActivitiesLoaded(
        activities: [activity1],
        savedIds: {'act-1'},
        noticeMessage: 'Aviso temporal',
      ),
      act: (b) => b.add(const SavedActivitiesNoticeDismissed()),
      expect: () => [
        const SavedActivitiesLoaded(
          activities: [activity1],
          savedIds: {'act-1'},
          noticeMessage: null,
        ),
      ],
    );
  });
}
