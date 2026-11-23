import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/blocked_user.dart';
import '../../domain/repositories/block_repository.dart';
import '../datasources/block_remote_datasource.dart';

class BlockRepositoryImpl implements BlockRepository {
  final BlockRemoteDataSource remoteDataSource;

  BlockRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<BlockedUser>>> getBlockedUsers(String userId) {
    return _run(() => remoteDataSource.getBlockedUsers(userId));
  }

  @override
  Future<Either<Failure, Unit>> blockUser({
    required String blockerId,
    required String blockedId,
  }) {
    return _run(() async {
      await remoteDataSource.blockUser(
        blockerId: blockerId,
        blockedId: blockedId,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> unblockUser({
    required String blockerId,
    required String blockedId,
  }) {
    return _run(() async {
      await remoteDataSource.unblockUser(
        blockerId: blockerId,
        blockedId: blockedId,
      );
      return unit;
    });
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
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
