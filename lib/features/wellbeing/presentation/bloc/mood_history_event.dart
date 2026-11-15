import 'package:equatable/equatable.dart';

sealed class MoodHistoryEvent extends Equatable {
  const MoodHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Pide el historial. Sirve tanto para la carga inicial como para reintentar
/// después de un error.
class MoodHistoryRequested extends MoodHistoryEvent {
  const MoodHistoryRequested();
}
