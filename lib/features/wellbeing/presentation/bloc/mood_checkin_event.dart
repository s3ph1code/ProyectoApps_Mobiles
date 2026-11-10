import 'package:equatable/equatable.dart';

sealed class MoodCheckinEvent extends Equatable {
  const MoodCheckinEvent();

  @override
  List<Object?> get props => [];
}

class MoodCheckinSubmitted extends MoodCheckinEvent {
  /// `null` cuando la usuaria todavía no eligió cómo se siente.
  final int? moodScore;
  final String? note;

  const MoodCheckinSubmitted({required this.moodScore, this.note});

  @override
  List<Object?> get props => [moodScore, note];
}
