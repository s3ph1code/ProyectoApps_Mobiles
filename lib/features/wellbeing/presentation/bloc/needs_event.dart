import 'package:equatable/equatable.dart';

sealed class NeedsEvent extends Equatable {
  const NeedsEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial y reintento de las opciones.
class NeedOptionsRequested extends NeedsEvent {
  const NeedOptionsRequested();
}

/// Marca o desmarca una opción.
class NeedOptionToggled extends NeedsEvent {
  final String optionId;

  const NeedOptionToggled(this.optionId);

  @override
  List<Object?> get props => [optionId];
}

/// Continuar: guarda la consulta y pide las recomendaciones.
class NeedsSubmitted extends NeedsEvent {
  const NeedsSubmitted();
}
