import 'package:equatable/equatable.dart';

/// Un registro de cómo se sintió la usuaria en un momento dado.
///
/// [moodScore] va de 1 (muy mal) a 5 (muy bien). [note] es opcional.
class MoodCheckin extends Equatable {
  final String id;
  final int moodScore;
  final String? note;
  final DateTime recordedAt;

  const MoodCheckin({
    required this.id,
    required this.moodScore,
    this.note,
    required this.recordedAt,
  });

  @override
  List<Object?> get props => [id, moodScore, note, recordedAt];
}
