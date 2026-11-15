import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity.dart';
import '../repositories/activities_repository.dart';

/// Los microdescansos publicados, opcionalmente de una sola categoría.
///
/// Una categoría vacía o en blanco significa «Todas», así la pantalla puede
/// pasar lo que tenga seleccionado sin decidir nada.
class GetActivities implements UseCase<List<Activity>, GetActivitiesParams> {
  final ActivitiesRepository repository;

  GetActivities(this.repository);

  @override
  Future<Either<Failure, List<Activity>>> call(GetActivitiesParams params) {
    final categoryId = params.categoryId?.trim();

    return repository.getActivities(
      categoryId: (categoryId == null || categoryId.isEmpty)
          ? null
          : categoryId,
    );
  }
}

class GetActivitiesParams extends Equatable {
  final String? categoryId;

  const GetActivitiesParams({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}
