import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:doulapp/features/auth/data/models/auth_user_model.dart';
import 'package:doulapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource dataSource;
  late AuthRepositoryImpl repository;

  const email = 'ana@icesi.edu.co';
  const password = 'contrasena-larga';
  const user = AuthUserModel(id: 'uuid-1', email: email);

  setUp(() {
    dataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: dataSource);
  });

  group('signUp', () {
    test('devuelve el usuario cuando el registro funciona', () async {
      when(() => dataSource.signUp(email: email, password: password, displayName: null))
          .thenAnswer((_) async => user);

      final result = await repository.signUp(email: email, password: password);

      expect(result, const Right<Failure, AuthUserModel>(user));
      verify(() => dataSource.signUp(email: email, password: password, displayName: null)).called(1);
    });

    test('traduce un correo ya registrado', () async {
      when(() => dataSource.signUp(email: email, password: password, displayName: null)).thenThrow(
        const AuthException('User already registered', code: 'email_exists'),
      );

      final result = await repository.signUp(email: email, password: password);

      expect(result, const Left<Failure, AuthUserModel>(EmailAlreadyRegisteredFailure()));
    });

    test('traduce una contraseña demasiado corta', () async {
      when(() => dataSource.signUp(email: email, password: '123', displayName: null)).thenThrow(
        const AuthException('Password is too short', code: 'weak_password'),
      );

      final result = await repository.signUp(email: email, password: '123');

      expect(result, const Left<Failure, AuthUserModel>(WeakPasswordFailure()));
    });
  });

  group('signIn', () {
    test('devuelve el usuario cuando las credenciales son correctas', () async {
      when(() => dataSource.signIn(email: email, password: password))
          .thenAnswer((_) async => user);

      final result = await repository.signIn(email: email, password: password);

      expect(result, const Right<Failure, AuthUserModel>(user));
    });

    test('traduce credenciales inválidas', () async {
      when(() => dataSource.signIn(email: email, password: password)).thenThrow(
        const AuthException('Invalid login credentials', code: 'invalid_credentials'),
      );

      final result = await repository.signIn(email: email, password: password);

      expect(result, const Left<Failure, AuthUserModel>(InvalidCredentialsFailure()));
    });

    test('traduce un correo sin confirmar', () async {
      when(() => dataSource.signIn(email: email, password: password)).thenThrow(
        const AuthException('Email not confirmed', code: 'email_not_confirmed'),
      );

      final result = await repository.signIn(email: email, password: password);

      expect(result, const Left<Failure, AuthUserModel>(EmailNotConfirmedFailure()));
    });

    test('cae en el mensaje cuando Supabase no envía código', () async {
      when(() => dataSource.signIn(email: email, password: password))
          .thenThrow(const AuthException('Invalid login credentials'));

      final result = await repository.signIn(email: email, password: password);

      expect(result, const Left<Failure, AuthUserModel>(InvalidCredentialsFailure()));
    });

    test('traduce la falta de conexión', () async {
      when(() => dataSource.signIn(email: email, password: password))
          .thenThrow(const NetworkException('sin red'));

      final result = await repository.signIn(email: email, password: password);

      expect(result, const Left<Failure, AuthUserModel>(NetworkFailure()));
    });

    test('un error desconocido no se filtra a la presentación', () async {
      when(() => dataSource.signIn(email: email, password: password))
          .thenThrow(ArgumentError('algo raro'));

      final result = await repository.signIn(email: email, password: password);

      expect(result, const Left<Failure, AuthUserModel>(UnexpectedFailure()));
    });
  });

  group('signOut', () {
    test('devuelve Right cuando la sesión se cierra', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result.isRight(), isTrue);
      verify(() => dataSource.signOut()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('devuelve el usuario cuando hay sesión', () async {
      when(() => dataSource.getCurrentUser()).thenAnswer((_) async => user);

      final result = await repository.getCurrentUser();

      expect(result, const Right<Failure, AuthUserModel?>(user));
    });

    test('no tener sesión no es un error', () async {
      when(() => dataSource.getCurrentUser()).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, const Right<Failure, AuthUserModel?>(null));
    });
  });

  group('sendPasswordReset', () {
    test('devuelve Right cuando el enlace se envía', () async {
      when(() => dataSource.sendPasswordReset(email)).thenAnswer((_) async {});

      final result = await repository.sendPasswordReset(email);

      expect(result.isRight(), isTrue);
      verify(() => dataSource.sendPasswordReset(email)).called(1);
    });

    test('traduce el límite de intentos', () async {
      when(() => dataSource.sendPasswordReset(email)).thenThrow(
        const AuthException('rate limit', code: 'over_email_send_rate_limit'),
      );

      final result = await repository.sendPasswordReset(email);

      expect(result, const Left<Failure, void>(TooManyAttemptsFailure()));
    });

    test('traduce la falta de conexión', () async {
      when(() => dataSource.sendPasswordReset(email))
          .thenThrow(const NetworkException('sin red'));

      final result = await repository.sendPasswordReset(email);

      expect(result, const Left<Failure, void>(NetworkFailure()));
    });
  });
}
