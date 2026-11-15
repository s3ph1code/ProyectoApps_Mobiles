import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/activity.dart';
import '../entities/activity_category.dart';

abstract class ActivitiesRepository {
  /// Las categorías activas, en orden alfabético.
  Future<Either<Failure, List<ActivityCategory>>> getCategories();

  /// Las actividades publicadas; con [categoryId] solo las de esa categoría.
  Future<Either<Failure, List<Activity>>> getActivities({String? categoryId});

  /// Una actividad publicada por su id, con sus pasos y su enlace.
  Future<Either<Failure, Activity>> getActivityById(String activityId);
}
