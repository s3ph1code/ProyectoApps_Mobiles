import 'package:equatable/equatable.dart';

import '../../domain/entities/activity.dart';

sealed class ActivityDetailState extends Equatable {
  const ActivityDetailState();

  @override
  List<Object?> get props => [];
}

class ActivityDetailInitial extends ActivityDetailState {
  const ActivityDetailInitial();
}

class ActivityDetailLoading extends ActivityDetailState {
  const ActivityDetailLoading();
}

class ActivityDetailLoaded extends ActivityDetailState {
  final Activity activity;

  const ActivityDetailLoaded(this.activity);

  bool get hasSteps =>
      activity.contentText != null && activity.contentText!.isNotEmpty;

  bool get hasExternalLink =>
      activity.externalUrl != null && activity.externalUrl!.isNotEmpty;

  @override
  List<Object?> get props => [activity];
}

/// La actividad no existe o no está publicada. Es distinto de un error
/// transitorio: no sirve reintentar, hay que volver a la lista.
class ActivityDetailNotFound extends ActivityDetailState {
  final String message;

  const ActivityDetailNotFound(this.message);

  @override
  List<Object?> get props => [message];
}

class ActivityDetailFailure extends ActivityDetailState {
  final String message;

  const ActivityDetailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
