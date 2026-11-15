import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/activity.dart';
import '../entities/activity_category.dart';
import '../entities/activity_session.dart';

abstract class ActivitiesRepository {
  /// Las categorías activas, en orden alfabético.
  Future<Either<Failure, List<ActivityCategory>>> getCategories();

  /// Las actividades publicadas; con [categoryId] solo las de esa categoría.
  Future<Either<Failure, List<Activity>>> getActivities({String? categoryId});

  /// Una actividad publicada por su id, con sus pasos y su enlace.
  Future<Either<Failure, Activity>> getActivityById(String activityId);

  /// Crea una sesión en estado 'in_progress' para la actividad.
  Future<Either<Failure, ActivitySession>> startSession({
    required String userId,
    required String activityId,
  });

  /// Finaliza la sesión marcándola como 'completed' y registrando el tiempo.
  Future<Either<Failure, ActivitySession>> finishSession({
    required String sessionId,
    required int elapsedSeconds,
  });

  /// Abandona la sesión marcándola como 'abandoned' y registrando el tiempo.
  Future<Either<Failure, ActivitySession>> abandonSession({
    required String sessionId,
    required int elapsedSeconds,
  });
}
