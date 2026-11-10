import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:doulapp/features/preferences/data/models/user_preferences_model.dart';
import 'package:doulapp/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:doulapp/features/preferences/domain/entities/profile_visibility.dart';
import 'package:doulapp/features/preferences/domain/entities/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataSource extends Mock implements PreferencesRemoteDataSource {}

void main() {
  late MockDataSource dataSource;
  late PreferencesRepositoryImpl repository;

  const model = UserPreferencesModel(
    profileVisibility: ProfileVisibility.community,
    allowNotifications: true,
    wellbeingReminders: true,
    languageCode: 'es',
  );

  setUpAll(() => registerFallbackValue(model));
  setUp(() {
    dataSource = MockDataSource();
    repository = PreferencesRepositoryImpl(remoteDataSource: dataSource);
  });

  test('getPreferences devuelve las preferencias', () async {
    when(() => dataSource.getPreferences('u')).thenAnswer((_) async => model);

    expect(
      await repository.getPreferences('u'),
      const Right<Failure, UserPreferences>(model),
    );
  });

  test('updatePreferences devuelve lo guardado', () async {
    when(
      () => dataSource.updatePreferences('u', any()),
    ).thenAnswer((_) async => model);

    expect(
      await repository.updatePreferences('u', model),
      const Right<Failure, UserPreferences>(model),
    );
  });

  const cases = <String, (Exception, Failure)>{
    'ServerException': (ServerException('x'), ServerFailure()),
    'NetworkException': (NetworkException('x'), NetworkFailure()),
    'UnauthenticatedException': (
      UnauthenticatedException(),
      UnauthenticatedFailure(),
    ),
  };
  cases.forEach((name, pair) {
    test('mapea $name a su Failure', () async {
      when(() => dataSource.getPreferences('u')).thenThrow(pair.$1);

      expect(
        await repository.getPreferences('u'),
        Left<Failure, UserPreferences>(pair.$2),
      );
    });
  });
}
