import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthUser>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _run(
      () => remoteDataSource.signUp(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  }) {
    return _run(() => remoteDataSource.signIn(email: email, password: password));
  }

  @override
  Future<Either<Failure, void>> signOut() => _run(remoteDataSource.signOut);

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() =>
      _run(remoteDataSource.getCurrentUser);

  @override
  Stream<AuthUser?> authStateChanges() => remoteDataSource.authStateChanges();

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(_failureFor(e));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnauthenticatedException {
      return const Left(UnauthenticatedFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  /// Supabase identifica el motivo con un código estable; el mensaje de texto
  /// cambia entre versiones, así que solo se consulta como último recurso.
  Failure _failureFor(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return const InvalidCredentialsFailure();
      case 'email_exists':
      case 'user_already_exists':
      case 'identity_already_exists':
        return const EmailAlreadyRegisteredFailure();
      case 'weak_password':
        return const WeakPasswordFailure();
      case 'email_address_invalid':
      case 'validation_failed':
        return const InvalidEmailFailure();
      case 'email_not_confirmed':
        return const EmailNotConfirmedFailure();
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return const TooManyAttemptsFailure();
      case 'session_not_found':
      case 'session_expired':
        return const UnauthenticatedFailure();
    }

    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return const InvalidCredentialsFailure();
    }
    if (message.contains('already registered')) {
      return const EmailAlreadyRegisteredFailure();
    }
    if (message.contains('password should be')) {
      return const WeakPasswordFailure();
    }
    if (message.contains('email not confirmed')) {
      return const EmailNotConfirmedFailure();
    }
    return const UnexpectedFailure();
  }
}
