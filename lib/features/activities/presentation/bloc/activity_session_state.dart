import 'package:equatable/equatable.dart';

import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_session.dart';

sealed class ActivitySessionState extends Equatable {
  const ActivitySessionState();

  @override
  List<Object?> get props => [];
}

class ActivitySessionInitial extends ActivitySessionState {
  const ActivitySessionInitial();
}

class ActivitySessionStarting extends ActivitySessionState {
  final Activity activity;

  const ActivitySessionStarting(this.activity);

  @override
  List<Object?> get props => [activity];
}

class ActivitySessionActive extends ActivitySessionState {
  final Activity activity;
  final ActivitySession? session;
  final int elapsedSeconds;
  final String? sessionWarning;

  const ActivitySessionActive({
    required this.activity,
    this.session,
    this.elapsedSeconds = 0,
    this.sessionWarning,
  });

  ActivitySessionActive copyWith({
    Activity? activity,
    ActivitySession? session,
    int? elapsedSeconds,
    String? sessionWarning,
  }) {
    return ActivitySessionActive(
      activity: activity ?? this.activity,
      session: session ?? this.session,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      sessionWarning: sessionWarning ?? this.sessionWarning,
    );
  }

  @override
  List<Object?> get props => [
    activity,
    session,
    elapsedSeconds,
    sessionWarning,
  ];
}

class ActivitySessionCompleted extends ActivitySessionState {
  final Activity activity;
  final ActivitySession? session;
  final int elapsedSeconds;

  const ActivitySessionCompleted({
    required this.activity,
    this.session,
    required this.elapsedSeconds,
  });

  @override
  List<Object?> get props => [activity, session, elapsedSeconds];
}

class ActivitySessionAbandonedState extends ActivitySessionState {
  final Activity activity;
  final int elapsedSeconds;

  const ActivitySessionAbandonedState({
    required this.activity,
    required this.elapsedSeconds,
  });

  @override
  List<Object?> get props => [activity, elapsedSeconds];
}
