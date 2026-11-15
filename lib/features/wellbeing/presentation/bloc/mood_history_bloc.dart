import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_mood_history.dart';
import 'mood_history_event.dart';
import 'mood_history_state.dart';

/// Carga los check-ins de la usuaria en sesión. Solo lee: quien no tiene
/// sesión no ve nada, y la RLS garantiza que nadie vea registros ajenos.
class MoodHistoryBloc extends Bloc<MoodHistoryEvent, MoodHistoryState> {
  final GetCurrentUser getCurrentUser;
  final GetMoodHistory getMoodHistory;

  MoodHistoryBloc({required this.getCurrentUser, required this.getMoodHistory})
    : super(const MoodHistoryInitial()) {
    on<MoodHistoryRequested>(_onRequested);
  }

  Future<void> _onRequested(
    MoodHistoryRequested event,
    Emitter<MoodHistoryState> emit,
  ) async {
    if (state is MoodHistoryLoading) return;
    emit(const MoodHistoryLoading());

    final userResult = await getCurrentUser(const NoParams());
    final user = userResult.fold((_) => null, (user) => user);
    if (user == null) {
      emit(
        MoodHistoryFailure(
          userResult.fold(
            (failure) => failure.message,
            (_) => const UnauthenticatedFailure().message,
          ),
        ),
      );
      return;
    }

    final result = await getMoodHistory(GetMoodHistoryParams(userId: user.id));

    result.fold(
      (failure) => emit(MoodHistoryFailure(failure.message)),
      (history) => emit(MoodHistoryLoaded(history)),
    );
  }
}
