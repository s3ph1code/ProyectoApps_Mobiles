import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity_category.dart';
import '../repositories/activities_repository.dart';

/// Las categorías con las que se filtran los microdescansos.
class GetActivityCategories
    implements UseCase<List<ActivityCategory>, NoParams> {
  final ActivitiesRepository repository;

  GetActivityCategories(this.repository);

  @override
  Future<Either<Failure, List<ActivityCategory>>> call(NoParams params) {
    return repository.getCategories();
  }
}
