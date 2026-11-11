import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_role.dart';
import '../entities/avatar_image.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> createProfile({
    required String userId,
    required String displayName,
  });

  Future<Either<Failure, Profile>> getProfile(String userId);

  Future<Either<Failure, Profile>> updateProfile(Profile profile);

  /// Sube [image] como foto de [profile] y devuelve el perfil con su nueva
  /// `avatarUrl`. Reemplaza la foto anterior, si había.
  Future<Either<Failure, Profile>> uploadAvatar({
    required Profile profile,
    required AvatarImage image,
  });

  /// Quita la foto de [profile] y devuelve el perfil sin `avatarUrl`.
  Future<Either<Failure, Profile>> removeAvatar(Profile profile);

  /// Roles asignados a la cuenta. Toda cuenta tiene al menos [AppRole.user].
  Future<Either<Failure, List<AppRole>>> getRoles(String userId);
}
