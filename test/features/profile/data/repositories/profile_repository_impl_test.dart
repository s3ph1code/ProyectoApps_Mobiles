import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:doulapp/features/profile/data/models/profile_model.dart';
import 'package:doulapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

void main() {
  late MockProfileRemoteDataSource dataSource;
  late ProfileRepositoryImpl repository;

  final model = ProfileModel(
    id: 'uuid-1',
    displayName: 'Ana',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 10),
    updatedAt: DateTime.utc(2026, 1, 10),
  );

  setUpAll(() {
    registerFallbackValue(model);
  });

  setUp(() {
    dataSource = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(remoteDataSource: dataSource);
  });

  group('createProfile', () {
    test('devuelve el perfil guardado', () async {
      when(
        () => dataSource.createProfile(userId: 'uuid-1', displayName: 'Ana'),
      ).thenAnswer((_) async => model);

      final result = await repository.createProfile(
        userId: 'uuid-1',
        displayName: 'Ana',
      );

      expect(result, Right<Failure, Profile>(model));
    });

    test('traduce una sesión terminada', () async {
      when(
        () => dataSource.createProfile(userId: 'uuid-1', displayName: 'Ana'),
      ).thenThrow(const AuthException('JWT expired', code: 'session_expired'));

      final result = await repository.createProfile(
        userId: 'uuid-1',
        displayName: 'Ana',
      );

      expect(result, const Left<Failure, Profile>(UnauthenticatedFailure()));
    });
  });

  group('getProfile', () {
    test('devuelve el perfil de la usuaria', () async {
      when(() => dataSource.getProfile('uuid-1'))
          .thenAnswer((_) async => model);

      final result = await repository.getProfile('uuid-1');

      expect(result, Right<Failure, Profile>(model));
    });

    test('traduce un fallo de red', () async {
      when(() => dataSource.getProfile('uuid-1'))
          .thenThrow(const NetworkException('sin conexión'));

      final result = await repository.getProfile('uuid-1');

      expect(result, const Left<Failure, Profile>(NetworkFailure()));
    });

    test('traduce un error del backend', () async {
      when(() => dataSource.getProfile('uuid-1'))
          .thenThrow(const ServerException('500'));

      final result = await repository.getProfile('uuid-1');

      expect(result, const Left<Failure, Profile>(ServerFailure()));
    });

    test('traduce un error inesperado sin exponer la excepción', () async {
      when(() => dataSource.getProfile('uuid-1')).thenThrow(StateError('x'));

      final result = await repository.getProfile('uuid-1');

      expect(result, const Left<Failure, Profile>(UnexpectedFailure()));
    });
  });

  group('updateProfile', () {
    test('envía el perfil como modelo y devuelve el actualizado', () async {
      when(() => dataSource.updateProfile(any()))
          .thenAnswer((_) async => model);

      final result = await repository.updateProfile(model);

      expect(result, Right<Failure, Profile>(model));
      verify(() => dataSource.updateProfile(model)).called(1);
    });
  });
}
