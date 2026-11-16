import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity.dart';
import '../repositories/activities_repository.dart';

/// Consulta las actividades guardadas por una usuaria, del más reciente al más antiguo.
class GetSavedActivities
    implements UseCase<List<Activity>, GetSavedActivitiesParams> {
  final ActivitiesRepository repository;

  GetSavedActivities(this.repository);

  @override
  Future<Either<Failure, List<Activity>>> call(GetSavedActivitiesParams params) {
    final userId = params.userId.trim();
    if (userId.isEmpty) {
      return Future.value(const Left(UnauthenticatedFailure()));
    }
    return repository.getSavedActivities(userId: userId);
  }
}

class GetSavedActivitiesParams extends Equatable {
  final String userId;

  const GetSavedActivitiesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
