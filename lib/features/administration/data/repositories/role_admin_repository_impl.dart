import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/role_admin_repository.dart';
import '../datasources/role_admin_remote_datasource.dart';

class RoleAdminRepositoryImpl implements RoleAdminRepository {
  final RoleAdminRemoteDataSource remoteDataSource;

  RoleAdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ManagedUser>>> searchUsers(String query) {
    return _run<List<ManagedUser>>(
      () => query.isEmpty
          ? remoteDataSource.getTeam()
          : remoteDataSource.searchUsers(query),
    );
  }

  @override
  Future<Either<Failure, Unit>> assignRole({
    required String userId,
    required AppRole role,
  }) {
    return _run(() async {
      await remoteDataSource.assignRole(userId: userId, role: role);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> removeRole({
    required String userId,
    required AppRole role,
  }) {
    return _run(() async {
      await remoteDataSource.removeRole(userId: userId, role: role);
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
