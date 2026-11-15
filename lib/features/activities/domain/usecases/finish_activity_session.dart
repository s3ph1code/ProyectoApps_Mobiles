import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity_session.dart';
import '../repositories/activities_repository.dart';

class FinishActivitySession
    implements UseCase<ActivitySession, FinishActivitySessionParams> {
  final ActivitiesRepository repository;

  FinishActivitySession(this.repository);

  @override
  Future<Either<Failure, ActivitySession>> call(
    FinishActivitySessionParams params,
  ) {
    if (params.sessionId.trim().isEmpty || params.elapsedSeconds < 0) {
      return Future.value(const Left(InvalidSessionFailure()));
    }
    return repository.finishSession(
      sessionId: params.sessionId,
      elapsedSeconds: params.elapsedSeconds,
    );
  }
}

class FinishActivitySessionParams extends Equatable {
  final String sessionId;
  final int elapsedSeconds;

  const FinishActivitySessionParams({
    required this.sessionId,
    required this.elapsedSeconds,
  });

  @override
  List<Object?> get props => [sessionId, elapsedSeconds];
}
