import '../../domain/entities/activity_session.dart';

class ActivitySessionModel extends ActivitySession {
  const ActivitySessionModel({
    required super.id,
    required super.userId,
    required super.activityId,
    required super.startedAt,
    super.completedAt,
    required super.status,
    super.elapsedSeconds,
  });

  factory ActivitySessionModel.fromJson(Map<String, dynamic> json) {
    return ActivitySessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityId: json['activity_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      status: ActivitySessionStatus.fromCode(json['status'] as String),
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'activity_id': activityId,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'status': status.code,
    'elapsed_seconds': elapsedSeconds,
  };
}
