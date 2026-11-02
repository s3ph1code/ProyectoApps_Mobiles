import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Observa la sesión: emite el usuario autenticado o `null` al cerrarla.
class WatchAuthState implements StreamUseCase<AuthUser?, NoParams> {
  final AuthRepository repository;

  WatchAuthState(this.repository);

  @override
  Stream<AuthUser?> call(NoParams params) => repository.authStateChanges();
}
