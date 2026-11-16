import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/activities_repository.dart';

/// Quita una actividad de la colección personal de la usuaria.
class UnsaveActivity implements UseCase<void, UnsaveActivityParams> {
  final ActivitiesRepository repository;

  UnsaveActivity(this.repository);

  @override
  Future<Either<Failure, void>> call(UnsaveActivityParams params) {
    final userId = params.userId.trim();
    final activityId = params.activityId.trim();

    if (userId.isEmpty) {
      return Future.value(const Left(UnauthenticatedFailure()));
    }
    if (activityId.isEmpty) {
      return Future.value(const Left(ActivityNotFoundFailure()));
    }

    return repository.unsaveActivity(userId: userId, activityId: activityId);
  }
}

class UnsaveActivityParams extends Equatable {
  final String userId;
  final String activityId;

  const UnsaveActivityParams({
    required this.userId,
    required this.activityId,
  });

  @override
  List<Object?> get props => [userId, activityId];
}
