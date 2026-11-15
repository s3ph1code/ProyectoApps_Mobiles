import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity_session.dart';
import '../repositories/activities_repository.dart';

class StartActivitySession
    implements UseCase<ActivitySession, StartActivitySessionParams> {
  final ActivitiesRepository repository;

  StartActivitySession(this.repository);

  @override
  Future<Either<Failure, ActivitySession>> call(
    StartActivitySessionParams params,
  ) {
    if (params.userId.trim().isEmpty || params.activityId.trim().isEmpty) {
      return Future.value(const Left(InvalidSessionFailure()));
    }
    return repository.startSession(
      userId: params.userId,
      activityId: params.activityId,
    );
  }
}

class StartActivitySessionParams extends Equatable {
  final String userId;
  final String activityId;

  const StartActivitySessionParams({
    required this.userId,
    required this.activityId,
  });

  @override
  List<Object?> get props => [userId, activityId];
}
