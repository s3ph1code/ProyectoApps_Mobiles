import 'package:equatable/equatable.dart';

import '../../domain/entities/report_status.dart';

sealed class ModerationEvent extends Equatable {
  const ModerationEvent();

  @override
  List<Object?> get props => [];
}

/// Abre el panel: carga los reportes pendientes.
class ModerationStarted extends ModerationEvent {
  const ModerationStarted();
}

class ModerationFilterChanged extends ModerationEvent {
  final ReportStatus status;

  const ModerationFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Vuelve a pedir la lista del filtro actual (al regresar del detalle o al
/// reintentar).
class ModerationRefreshed extends ModerationEvent {
  const ModerationRefreshed();
}
