import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> signUp({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signOut();

  /// `Right(null)` cuando no hay sesión activa: no tener sesión no es un error.
  Future<Either<Failure, AuthUser?>> getCurrentUser();

  /// Emite el usuario cada vez que la sesión cambia: `null` cuando no hay
  /// sesión activa.
  Stream<AuthUser?> authStateChanges();
}
