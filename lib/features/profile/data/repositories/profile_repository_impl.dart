import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_role.dart';
import '../../domain/entities/avatar_image.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Profile>> createProfile({
    required String userId,
    required String displayName,
  }) {
    return _run(
      () => remoteDataSource.createProfile(
        userId: userId,
        displayName: displayName,
      ),
    );
  }

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) {
    return _run(() => remoteDataSource.getProfile(userId));
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(Profile profile) {
    return _run(
      () => remoteDataSource.updateProfile(ProfileModel.fromEntity(profile)),
    );
  }

  @override
  Future<Either<Failure, Profile>> uploadAvatar({
    required Profile profile,
    required AvatarImage image,
  }) {
    return _run(
      () => remoteDataSource.uploadAvatar(
        userId: profile.id,
        bytes: image.bytes,
        mimeType: image.mimeType,
        previousAvatarUrl: profile.avatarUrl,
      ),
    );
  }

  @override
  Future<Either<Failure, Profile>> removeAvatar(Profile profile) {
    return _run(
      () => remoteDataSource.removeAvatar(
        userId: profile.id,
        previousAvatarUrl: profile.avatarUrl,
      ),
    );
  }

  @override
  Future<Either<Failure, List<AppRole>>> getRoles(String userId) async {
    try {
      return Right(await remoteDataSource.getRoles(userId));
    } on UnauthenticatedException {
      return const Left(UnauthenticatedFailure());
    } on AuthException {
      return const Left(UnauthenticatedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  Future<Either<Failure, Profile>> _run(
    Future<ProfileModel> Function() action,
  ) async {
    try {
      return Right(await action());
    } on UnauthenticatedException {
      return const Left(UnauthenticatedFailure());
    } on AuthException {
      return const Left(UnauthenticatedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
