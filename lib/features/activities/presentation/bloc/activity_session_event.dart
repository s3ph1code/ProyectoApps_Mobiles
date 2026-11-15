import 'package:equatable/equatable.dart';

import '../../domain/entities/activity.dart';

sealed class ActivitySessionEvent extends Equatable {
  const ActivitySessionEvent();

  @override
  List<Object?> get props => [];
}

class ActivitySessionStarted extends ActivitySessionEvent {
  final Activity activity;

  const ActivitySessionStarted(this.activity);

  @override
  List<Object?> get props => [activity];
}

class ActivitySessionTicked extends ActivitySessionEvent {
  final int elapsedSeconds;

  const ActivitySessionTicked(this.elapsedSeconds);

  @override
  List<Object?> get props => [elapsedSeconds];
}

class ActivitySessionFinished extends ActivitySessionEvent {
  const ActivitySessionFinished();
}

class ActivitySessionAbandoned extends ActivitySessionEvent {
  const ActivitySessionAbandoned();
}
