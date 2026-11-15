import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity.dart';
import '../repositories/activities_repository.dart';

/// El detalle de una actividad publicada.
///
/// Un id vacío no se consulta: equivale a una actividad que no existe, que es
/// justo lo que la pantalla debe mostrar.
class GetActivityById implements UseCase<Activity, GetActivityByIdParams> {
  final ActivitiesRepository repository;

  GetActivityById(this.repository);

  @override
  Future<Either<Failure, Activity>> call(GetActivityByIdParams params) {
    final activityId = params.activityId.trim();

    if (activityId.isEmpty) {
      return Future.value(const Left(ActivityNotFoundFailure()));
    }

    return repository.getActivityById(activityId);
  }
}

class GetActivityByIdParams extends Equatable {
  final String activityId;

  const GetActivityByIdParams({required this.activityId});

  @override
  List<Object?> get props => [activityId];
}
