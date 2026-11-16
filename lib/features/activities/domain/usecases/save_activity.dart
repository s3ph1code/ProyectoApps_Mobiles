import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/activities_repository.dart';

/// Guarda una actividad en la colección personal de la usuaria.
class SaveActivity implements UseCase<void, SaveActivityParams> {
  final ActivitiesRepository repository;

  SaveActivity(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveActivityParams params) {
    final userId = params.userId.trim();
    final activityId = params.activityId.trim();

    if (userId.isEmpty) {
      return Future.value(const Left(UnauthenticatedFailure()));
    }
    if (activityId.isEmpty) {
      return Future.value(const Left(ActivityNotFoundFailure()));
    }

    return repository.saveActivity(userId: userId, activityId: activityId);
  }
}

class SaveActivityParams extends Equatable {
  final String userId;
  final String activityId;

  const SaveActivityParams({
    required this.userId,
    required this.activityId,
  });

  @override
  List<Object?> get props => [userId, activityId];
}
