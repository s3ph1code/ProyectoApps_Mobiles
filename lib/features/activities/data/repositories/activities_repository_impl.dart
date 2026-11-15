import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_category.dart';
import '../../domain/repositories/activities_repository.dart';
import '../datasources/activities_remote_datasource.dart';

class ActivitiesRepositoryImpl implements ActivitiesRepository {
  final ActivitiesRemoteDataSource remoteDataSource;

  ActivitiesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ActivityCategory>>> getCategories() {
    return _guard(remoteDataSource.fetchCategories);
  }

  @override
  Future<Either<Failure, List<Activity>>> getActivities({String? categoryId}) {
    return _guard(
      () => remoteDataSource.fetchActivities(categoryId: categoryId),
    );
  }

  @override
  Future<Either<Failure, Activity>> getActivityById(String activityId) {
    return _guard(() => remoteDataSource.fetchActivityById(activityId));
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on NotFoundException {
      return const Left(ActivityNotFoundFailure());
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
