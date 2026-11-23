import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../repositories/role_admin_repository.dart';
import 'resolve_administrator.dart';
import 'role_params.dart';

/// Asigna el rol de moderadora. Es el único rol que se gestiona desde la app.
class AssignRole implements UseCase<Unit, RoleParams> {
  final ResolveAdministrator resolveAdministrator;
  final RoleAdminRepository repository;

  AssignRole({required this.resolveAdministrator, required this.repository});

  @override
  Future<Either<Failure, Unit>> call(RoleParams params) async {
    if (params.role != AppRole.moderator) {
      return const Left(RoleNotManageableFailure());
    }

    final access = await resolveAdministrator(const NoParams());
    return access.fold(
      (failure) => Left(failure),
      (_) => repository.assignRole(userId: params.userId, role: params.role),
    );
  }
}
