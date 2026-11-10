import 'package:equatable/equatable.dart';

import '../../domain/entities/mood_checkin.dart';

sealed class MoodCheckinState extends Equatable {
  const MoodCheckinState();

  @override
  List<Object?> get props => [];
}

class MoodCheckinInitial extends MoodCheckinState {
  const MoodCheckinInitial();
}

class MoodCheckinSaving extends MoodCheckinState {
  const MoodCheckinSaving();
}

class MoodCheckinSuccess extends MoodCheckinState {
  final MoodCheckin checkin;

  const MoodCheckinSuccess(this.checkin);

  @override
  List<Object?> get props => [checkin];
}

class MoodCheckinFailure extends MoodCheckinState {
  final String message;

  const MoodCheckinFailure(this.message);

  @override
  List<Object?> get props => [message];
}
