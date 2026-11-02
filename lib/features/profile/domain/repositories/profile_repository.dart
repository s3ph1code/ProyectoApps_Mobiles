import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_role.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> createProfile({
    required String userId,
    required String displayName,
  });

  Future<Either<Failure, Profile>> getProfile(String userId);

  Future<Either<Failure, Profile>> updateProfile(Profile profile);

  /// Roles asignados a la cuenta. Toda cuenta tiene al menos [AppRole.user].
  Future<Either<Failure, List<AppRole>>> getRoles(String userId);
}
