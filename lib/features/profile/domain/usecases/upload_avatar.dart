import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/avatar_image.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Sube la foto de perfil.
///
/// Solo se aceptan imágenes de los tipos [allowedMimeTypes] y de hasta
/// [maxBytes]. Si no cumple, no se sube nada y la foto actual se conserva.
class UploadAvatar implements UseCase<Profile, UploadAvatarParams> {
  static const maxBytes = 2 * 1024 * 1024;
  static const allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final ProfileRepository repository;

  UploadAvatar(this.repository);

  @override
  Future<Either<Failure, Profile>> call(UploadAvatarParams params) {
    final image = params.image;

    if (image.bytes.isEmpty || !allowedMimeTypes.contains(image.mimeType)) {
      return Future.value(const Left(AvatarTypeNotAllowedFailure()));
    }
    if (image.bytes.length > maxBytes) {
      return Future.value(const Left(AvatarTooLargeFailure()));
    }

    return repository.uploadAvatar(profile: params.profile, image: image);
  }
}

class UploadAvatarParams extends Equatable {
  final Profile profile;
  final AvatarImage image;

  const UploadAvatarParams({required this.profile, required this.image});

  @override
  List<Object?> get props => [profile, image];
}
