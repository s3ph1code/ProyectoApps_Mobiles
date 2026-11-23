import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../../../profile/domain/usecases/get_user_roles.dart';
import '../entities/administrator.dart';

/// Comprueba que la cuenta en sesión puede administrar
/// ([AppRole.canAdminister]). Todos los casos de uso de la administración
/// pasan por aquí.
class ResolveAdministrator implements UseCase<Administrator, NoParams> {
  final GetCurrentUser getCurrentUser;
  final GetUserRoles getUserRoles;

  ResolveAdministrator({
    required this.getCurrentUser,
    required this.getUserRoles,
  });

  @override
  Future<Either<Failure, Administrator>> call(NoParams params) async {
    final userResult = await getCurrentUser(const NoParams());
    final userId = userResult.fold((_) => null, (user) => user?.id);
    if (userId == null) return const Left(UnauthenticatedFailure());

    final rolesResult = await getUserRoles(GetUserRolesParams(userId: userId));
    return rolesResult.fold(
      (failure) => Left(failure),
      (roles) => roles.canAdminister
          ? Right(Administrator(userId: userId))
          : const Left(AdminForbiddenFailure()),
    );
  }
}
