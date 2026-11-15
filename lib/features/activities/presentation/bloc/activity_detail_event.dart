import 'package:equatable/equatable.dart';

sealed class ActivityDetailEvent extends Equatable {
  const ActivityDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Carga el detalle del id que llega por la ruta. Sirve también para
/// reintentar tras un error.
class ActivityDetailRequested extends ActivityDetailEvent {
  final String activityId;

  const ActivityDetailRequested(this.activityId);

  @override
  List<Object?> get props => [activityId];
}
