import '../../domain/entities/mood_checkin.dart';

class MoodCheckinModel extends MoodCheckin {
  const MoodCheckinModel({
    required super.id,
    required super.moodScore,
    super.note,
    required super.recordedAt,
  });

  factory MoodCheckinModel.fromJson(Map<String, dynamic> json) {
    return MoodCheckinModel(
      id: json['id'] as String,
      moodScore: (json['mood_score'] as num).toInt(),
      note: json['note'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}
