import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/usecases/save_mood_checkin.dart';
import 'mood_checkin_event.dart';
import 'mood_checkin_state.dart';

class MoodCheckinBloc extends Bloc<MoodCheckinEvent, MoodCheckinState> {
  final GetCurrentUser getCurrentUser;
  final SaveMoodCheckin saveMoodCheckin;

  MoodCheckinBloc({required this.getCurrentUser, required this.saveMoodCheckin})
    : super(const MoodCheckinInitial()) {
    on<MoodCheckinSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    MoodCheckinSubmitted event,
    Emitter<MoodCheckinState> emit,
  ) async {
    if (state is MoodCheckinSaving) return;
    emit(const MoodCheckinSaving());

    final userResult = await getCurrentUser(const NoParams());
    final user = userResult.fold((_) => null, (user) => user);
    if (user == null) {
      emit(
        MoodCheckinFailure(
          userResult.fold(
            (failure) => failure.message,
            (_) => const UnauthenticatedFailure().message,
          ),
        ),
      );
      return;
    }

    final result = await saveMoodCheckin(
      SaveMoodCheckinParams(
        userId: user.id,
        moodScore: event.moodScore,
        note: event.note,
      ),
    );

    result.fold(
      (failure) => emit(MoodCheckinFailure(failure.message)),
      (checkin) => emit(MoodCheckinSuccess(checkin)),
    );
  }
}
