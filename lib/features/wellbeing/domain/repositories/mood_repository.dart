import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/mood_checkin.dart';

abstract class MoodRepository {
  /// Guarda un check-in de [userId] y devuelve el registro creado.
  Future<Either<Failure, MoodCheckin>> saveCheckin({
    required String userId,
    required int moodScore,
    String? note,
  });

  /// Devuelve los check-ins de [userId], del más reciente al más antiguo,
  /// como máximo [limit].
  Future<Either<Failure, List<MoodCheckin>>> getHistory({
    required String userId,
    required int limit,
  });
}
