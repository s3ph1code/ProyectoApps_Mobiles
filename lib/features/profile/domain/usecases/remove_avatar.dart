import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Quita la foto de perfil. Sin foto no hay nada que hacer: devuelve el
/// mismo perfil sin tocar la red.
class RemoveAvatar implements UseCase<Profile, RemoveAvatarParams> {
  final ProfileRepository repository;

  RemoveAvatar(this.repository);

  @override
  Future<Either<Failure, Profile>> call(RemoveAvatarParams params) {
    if (params.profile.avatarUrl == null) {
      return Future.value(Right(params.profile));
    }
    return repository.removeAvatar(params.profile);
  }
}

class RemoveAvatarParams extends Equatable {
  final Profile profile;

  const RemoveAvatarParams({required this.profile});

  @override
  List<Object?> get props => [profile];
}
