import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/mood_checkin.dart';
import '../repositories/mood_repository.dart';

/// Guarda un check-in de ánimo.
///
/// El ánimo es obligatorio y va de [minScore] a [maxScore]; la nota es
/// opcional y admite hasta [maxNoteLength] caracteres. Una nota vacía se
/// guarda como ausente.
class SaveMoodCheckin implements UseCase<MoodCheckin, SaveMoodCheckinParams> {
  static const minScore = 1;
  static const maxScore = 5;
  static const maxNoteLength = 500;

  final MoodRepository repository;

  SaveMoodCheckin(this.repository);

  @override
  Future<Either<Failure, MoodCheckin>> call(SaveMoodCheckinParams params) {
    final score = params.moodScore;
    final note = params.note?.trim();

    if (score == null || score < minScore || score > maxScore) {
      return Future.value(const Left(MoodScoreRequiredFailure()));
    }
    if (note != null && note.length > maxNoteLength) {
      return Future.value(const Left(MoodNoteTooLongFailure()));
    }

    return repository.saveCheckin(
      userId: params.userId,
      moodScore: score,
      note: (note == null || note.isEmpty) ? null : note,
    );
  }
}

class SaveMoodCheckinParams extends Equatable {
  final String userId;
  final int? moodScore;
  final String? note;

  const SaveMoodCheckinParams({
    required this.userId,
    required this.moodScore,
    this.note,
  });

  @override
  List<Object?> get props => [userId, moodScore, note];
}
