import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> createProfile({
    required String userId,
    required String displayName,
  });

  Future<Either<Failure, Profile>> getProfile(String userId);

  Future<Either<Failure, Profile>> updateProfile(Profile profile);
}
