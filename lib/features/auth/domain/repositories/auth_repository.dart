import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  /// [displayName] viaja con el registro: el trigger `handle_new_user` lo usa
  /// como nombre del perfil, así el perfil nace completo y no depende de que
  /// la sesión ya esté activa (por ejemplo, si se exige confirmar el correo).
  Future<Either<Failure, AuthUser>> signUp({
    required String email,
    required String password,
    String? displayName,
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
