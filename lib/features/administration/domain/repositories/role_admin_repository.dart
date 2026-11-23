import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../entities/managed_user.dart';

abstract class RoleAdminRepository {
  /// Con [query] vacío devuelve el equipo (moderadoras y administradoras);
  /// si no, las usuarias cuyo nombre contiene [query].
  Future<Either<Failure, List<ManagedUser>>> searchUsers(String query);

  Future<Either<Failure, Unit>> assignRole({
    required String userId,
    required AppRole role,
  });

  Future<Either<Failure, Unit>> removeRole({
    required String userId,
    required AppRole role,
  });
}
