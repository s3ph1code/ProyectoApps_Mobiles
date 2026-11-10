import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Actualiza el nombre y la biografía del perfil.
///
/// Las reglas viven aquí y no en la pantalla: el nombre es obligatorio y
/// admite hasta [maxNameLength] caracteres; la biografía es opcional y admite
/// hasta [maxBioLength]. Una biografía vacía se guarda como ausente.
class UpdateProfile implements UseCase<Profile, UpdateProfileParams> {
  static const maxNameLength = 100;
  static const maxBioLength = 280;

  final ProfileRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(UpdateProfileParams params) async {
    final name = params.displayName.trim();
    final bio = params.bio?.trim();

    if (name.isEmpty) return const Left(MissingNameFailure());
    if (name.length > maxNameLength) return const Left(NameTooLongFailure());
    if (bio != null && bio.length > maxBioLength) {
      return const Left(BioTooLongFailure());
    }

    final current = params.profile;
    return repository.updateProfile(
      Profile(
        id: current.id,
        displayName: name,
        avatarUrl: current.avatarUrl,
        bio: (bio == null || bio.isEmpty) ? null : bio,
        accountStatus: current.accountStatus,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
      ),
    );
  }
}

class UpdateProfileParams extends Equatable {
  /// Perfil actual, del que se conservan los datos que no se editan.
  final Profile profile;
  final String displayName;
  final String? bio;

  const UpdateProfileParams({
    required this.profile,
    required this.displayName,
    this.bio,
  });

  @override
  List<Object?> get props => [profile, displayName, bio];
}
