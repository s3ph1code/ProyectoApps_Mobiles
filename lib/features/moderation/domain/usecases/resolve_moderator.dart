import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../../../profile/domain/usecases/get_user_roles.dart';
import '../entities/moderator.dart';

/// Comprueba que la cuenta en sesión puede moderar ([AppRole.canModerate]).
/// Es la única puerta del dominio: el resto de casos de uso pasan por aquí.
class ResolveModerator implements UseCase<Moderator, NoParams> {
  final GetCurrentUser getCurrentUser;
  final GetUserRoles getUserRoles;

  ResolveModerator({required this.getCurrentUser, required this.getUserRoles});

  @override
  Future<Either<Failure, Moderator>> call(NoParams params) async {
    final userResult = await getCurrentUser(const NoParams());
    final userId = userResult.fold((_) => null, (user) => user?.id);
    if (userId == null) return const Left(UnauthenticatedFailure());

    final rolesResult = await getUserRoles(GetUserRolesParams(userId: userId));
    return rolesResult.fold(
      (failure) => Left(failure),
      (roles) => roles.canModerate
          ? Right(Moderator(userId: userId))
          : const Left(ForbiddenFailure()),
    );
  }
}
