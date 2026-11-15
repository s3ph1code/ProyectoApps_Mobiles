import 'package:equatable/equatable.dart';

import '../../domain/entities/mood_checkin.dart';

sealed class MoodHistoryState extends Equatable {
  const MoodHistoryState();

  @override
  List<Object?> get props => [];
}

class MoodHistoryInitial extends MoodHistoryState {
  const MoodHistoryInitial();
}

class MoodHistoryLoading extends MoodHistoryState {
  const MoodHistoryLoading();
}

/// Historial cargado. Una lista vacía es un resultado válido: significa que
/// la usuaria todavía no tiene registros.
class MoodHistoryLoaded extends MoodHistoryState {
  final List<MoodCheckin> history;

  const MoodHistoryLoaded(this.history);

  bool get isEmpty => history.isEmpty;

  @override
  List<Object?> get props => [history];
}

class MoodHistoryFailure extends MoodHistoryState {
  final String message;

  const MoodHistoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
