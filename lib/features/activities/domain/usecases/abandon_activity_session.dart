import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity_session.dart';
import '../repositories/activities_repository.dart';

class AbandonActivitySession
    implements UseCase<ActivitySession, AbandonActivitySessionParams> {
  final ActivitiesRepository repository;

  AbandonActivitySession(this.repository);

  @override
  Future<Either<Failure, ActivitySession>> call(
    AbandonActivitySessionParams params,
  ) {
    if (params.sessionId.trim().isEmpty || params.elapsedSeconds < 0) {
      return Future.value(const Left(InvalidSessionFailure()));
    }
    return repository.abandonSession(
      sessionId: params.sessionId,
      elapsedSeconds: params.elapsedSeconds,
    );
  }
}

class AbandonActivitySessionParams extends Equatable {
  final String sessionId;
  final int elapsedSeconds;

  const AbandonActivitySessionParams({
    required this.sessionId,
    required this.elapsedSeconds,
  });

  @override
  List<Object?> get props => [sessionId, elapsedSeconds];
}
