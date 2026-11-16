import 'package:equatable/equatable.dart';

import '../../domain/entities/activity.dart';

sealed class SavedActivitiesEvent extends Equatable {
  const SavedActivitiesEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita cargar las actividades guardadas de la usuaria autenticada.
class SavedActivitiesRequested extends SavedActivitiesEvent {
  const SavedActivitiesRequested();
}

/// Alterna el guardado de una actividad (guardar si no lo está, o quitar de guardadas).
class ActivitySaveToggled extends SavedActivitiesEvent {
  final Activity activity;

  const ActivitySaveToggled(this.activity);

  @override
  List<Object?> get props => [activity];
}

/// Limpia el aviso transitorio (ej. tras mostrar un SnackBar).
class SavedActivitiesNoticeDismissed extends SavedActivitiesEvent {
  const SavedActivitiesNoticeDismissed();
}
