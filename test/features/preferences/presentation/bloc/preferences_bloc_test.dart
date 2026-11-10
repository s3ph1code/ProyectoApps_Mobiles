import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/preferences/domain/entities/profile_visibility.dart';
import 'package:doulapp/features/preferences/domain/entities/user_preferences.dart';
import 'package:doulapp/features/preferences/domain/usecases/get_preferences.dart';
import 'package:doulapp/features/preferences/domain/usecases/update_preferences.dart';
import 'package:doulapp/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:doulapp/features/preferences/presentation/bloc/preferences_event.dart';
import 'package:doulapp/features/preferences/presentation/bloc/preferences_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetPreferences extends Mock implements GetPreferences {}

class MockUpdatePreferences extends Mock implements UpdatePreferences {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetPreferences getPreferences;
  late MockUpdatePreferences updatePreferences;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
  const prefs = UserPreferences(
    profileVisibility: ProfileVisibility.community,
    allowNotifications: true,
    wellbeingReminders: true,
    languageCode: 'es',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetPreferencesParams(userId: ''));
    registerFallbackValue(
      const UpdatePreferencesParams(userId: '', preferences: prefs),
    );
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getPreferences = MockGetPreferences();
    updatePreferences = MockUpdatePreferences();
    when(
      () => getCurrentUser(any()),
    ).thenAnswer((_) async => const Right(user));
    when(
      () => getPreferences(any()),
    ).thenAnswer((_) async => const Right(prefs));
  });

  PreferencesBloc build() => PreferencesBloc(
    getCurrentUser: getCurrentUser,
    getPreferences: getPreferences,
    updatePreferences: updatePreferences,
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'carga las preferencias de la usuaria actual',
    build: build,
    act: (b) => b.add(const PreferencesLoadRequested()),
    expect: () => [
      const PreferencesLoading(),
      const PreferencesLoaded(preferences: prefs),
    ],
    verify: (_) => verify(
      () => getPreferences(const GetPreferencesParams(userId: 'uuid-1')),
    ).called(1),
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'falla si no hay sesión',
    build: () {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (b) => b.add(const PreferencesLoadRequested()),
    expect: () => [
      const PreferencesLoading(),
      PreferencesFailure(const UnauthenticatedFailure().message),
    ],
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'falla si no se pueden cargar',
    build: () {
      when(
        () => getPreferences(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (b) => b.add(const PreferencesLoadRequested()),
    expect: () => [
      const PreferencesLoading(),
      PreferencesFailure(const NetworkFailure().message),
    ],
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'guarda al instante: muestra el valor nuevo y luego lo confirma',
    build: () {
      when(() => updatePreferences(any())).thenAnswer(
        (i) async => Right(
          (i.positionalArguments.first as UpdatePreferencesParams).preferences,
        ),
      );
      return build();
    },
    act: (b) async {
      b.add(const PreferencesLoadRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const PreferencesNotificationsChanged(false));
    },
    skip: 2,
    expect: () {
      final next = prefs.copyWith(allowNotifications: false);
      return [
        PreferencesLoaded(preferences: next, isSaving: true),
        PreferencesLoaded(preferences: next),
      ];
    },
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'si el guardado falla vuelve al valor anterior y avisa',
    build: () {
      when(
        () => updatePreferences(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return build();
    },
    act: (b) async {
      b.add(const PreferencesLoadRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const PreferencesVisibilityChanged(ProfileVisibility.private));
    },
    skip: 2,
    expect: () => [
      PreferencesLoaded(
        preferences: prefs.copyWith(
          profileVisibility: ProfileVisibility.private,
        ),
        isSaving: true,
      ),
      PreferencesLoaded(
        preferences: prefs,
        errorMessage: const ServerFailure().message,
      ),
    ],
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'no guarda si el valor no cambió',
    build: build,
    act: (b) async {
      b.add(const PreferencesLoadRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const PreferencesRemindersChanged(true));
    },
    skip: 2,
    expect: () => <PreferencesState>[],
    verify: (_) => verifyNever(() => updatePreferences(any())),
  );

  blocTest<PreferencesBloc, PreferencesState>(
    'ignora cambios antes de cargar',
    build: build,
    act: (b) => b.add(const PreferencesRemindersChanged(false)),
    expect: () => <PreferencesState>[],
  );
}
