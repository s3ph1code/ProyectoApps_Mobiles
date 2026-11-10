import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/preferences/domain/entities/profile_visibility.dart';
import 'package:doulapp/features/preferences/domain/entities/user_preferences.dart';
import 'package:doulapp/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:doulapp/features/preferences/domain/usecases/get_preferences.dart';
import 'package:doulapp/features/preferences/domain/usecases/update_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesRepository extends Mock implements PreferencesRepository {}

void main() {
  late MockPreferencesRepository repository;

  const prefs = UserPreferences(
    profileVisibility: ProfileVisibility.community,
    allowNotifications: true,
    wellbeingReminders: true,
    languageCode: 'es',
  );

  setUpAll(() => registerFallbackValue(prefs));
  setUp(() => repository = MockPreferencesRepository());

  test('GetPreferences pide las preferencias de la usuaria', () async {
    when(
      () => repository.getPreferences('uuid-1'),
    ).thenAnswer((_) async => const Right(prefs));

    final result = await GetPreferences(repository)(
      const GetPreferencesParams(userId: 'uuid-1'),
    );

    expect(result, const Right<Failure, UserPreferences>(prefs));
  });

  test('UpdatePreferences guarda y devuelve lo guardado', () async {
    final next = prefs.copyWith(profileVisibility: ProfileVisibility.private);
    when(
      () => repository.updatePreferences('uuid-1', next),
    ).thenAnswer((_) async => Right(next));

    final result = await UpdatePreferences(repository)(
      UpdatePreferencesParams(userId: 'uuid-1', preferences: next),
    );

    expect(result, Right<Failure, UserPreferences>(next));
  });

  test('UpdatePreferences propaga el fallo del repositorio', () async {
    when(
      () => repository.updatePreferences(any(), any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await UpdatePreferences(repository)(
      const UpdatePreferencesParams(userId: 'uuid-1', preferences: prefs),
    );

    expect(result, const Left<Failure, UserPreferences>(NetworkFailure()));
  });

  test('copyWith conserva el idioma y cambia solo lo indicado', () {
    final next = prefs.copyWith(allowNotifications: false);
    expect(next.allowNotifications, isFalse);
    expect(next.wellbeingReminders, isTrue);
    expect(next.languageCode, 'es');
  });

  test('ProfileVisibility.fromCode usa comunidad si el código es raro', () {
    expect(ProfileVisibility.fromCode('private'), ProfileVisibility.private);
    expect(ProfileVisibility.fromCode('xyz'), ProfileVisibility.community);
  });
}
