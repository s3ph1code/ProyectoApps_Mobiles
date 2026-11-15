import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/mood_checkin.dart';
import '../repositories/mood_repository.dart';

/// Devuelve los check-ins de la usuaria, del más reciente al más antiguo.
///
/// Por omisión trae los últimos [defaultLimit]. El límite se acota entre 1 y
/// [maxLimit] para que la pantalla no pueda pedir una página sin tope.
class GetMoodHistory
    implements UseCase<List<MoodCheckin>, GetMoodHistoryParams> {
  static const defaultLimit = 30;
  static const maxLimit = 100;

  final MoodRepository repository;

  GetMoodHistory(this.repository);

  @override
  Future<Either<Failure, List<MoodCheckin>>> call(GetMoodHistoryParams params) {
    return repository.getHistory(
      userId: params.userId,
      limit: params.limit.clamp(1, maxLimit),
    );
  }
}

class GetMoodHistoryParams extends Equatable {
  final String userId;
  final int limit;

  const GetMoodHistoryParams({
    required this.userId,
    this.limit = GetMoodHistory.defaultLimit,
  });

  @override
  List<Object?> get props => [userId, limit];
}
