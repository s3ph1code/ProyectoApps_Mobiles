import 'package:equatable/equatable.dart';

enum ActivitySessionStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned');

  final String code;
  const ActivitySessionStatus(this.code);

  static ActivitySessionStatus fromCode(String code) {
    return switch (code) {
      'completed' => ActivitySessionStatus.completed,
      'abandoned' => ActivitySessionStatus.abandoned,
      _ => ActivitySessionStatus.inProgress,
    };
  }
}

/// Registro de una sesión de pausa o microdescanso realizada por la usuaria.
class ActivitySession extends Equatable {
  final String id;
  final String userId;
  final String activityId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final ActivitySessionStatus status;
  final int? elapsedSeconds;

  const ActivitySession({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.elapsedSeconds,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    activityId,
    startedAt,
    completedAt,
    status,
    elapsedSeconds,
  ];
}
