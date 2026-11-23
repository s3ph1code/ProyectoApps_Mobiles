import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../repositories/role_admin_repository.dart';
import 'resolve_administrator.dart';
import 'role_params.dart';

/// Quita el rol de moderadora. Nadie puede quitarse a sí misma el de
/// administradora (la base de datos también lo impide).
class RemoveRole implements UseCase<Unit, RoleParams> {
  final ResolveAdministrator resolveAdministrator;
  final RoleAdminRepository repository;

  RemoveRole({required this.resolveAdministrator, required this.repository});

  @override
  Future<Either<Failure, Unit>> call(RoleParams params) async {
    final access = await resolveAdministrator(const NoParams());
    final administrator = access.fold((_) => null, (admin) => admin);
    if (administrator == null) return access.map((_) => unit);

    if (params.role == AppRole.admin && params.userId == administrator.userId) {
      return const Left(CannotRemoveOwnAdminFailure());
    }
    if (params.role != AppRole.moderator) {
      return const Left(RoleNotManageableFailure());
    }

    return repository.removeRole(userId: params.userId, role: params.role);
  }
}
