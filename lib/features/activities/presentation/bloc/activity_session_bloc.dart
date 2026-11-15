import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/usecases/abandon_activity_session.dart';
import '../../domain/usecases/finish_activity_session.dart';
import '../../domain/usecases/start_activity_session.dart';
import 'activity_session_event.dart';
import 'activity_session_state.dart';

class ActivitySessionBloc
    extends Bloc<ActivitySessionEvent, ActivitySessionState> {
  final GetCurrentUser getCurrentUser;
  final StartActivitySession startActivitySession;
  final FinishActivitySession finishActivitySession;
  final AbandonActivitySession abandonActivitySession;
  final Stream<int> Function() _ticker;

  StreamSubscription<int>? _timerSubscription;

  ActivitySessionBloc({
    required this.getCurrentUser,
    required this.startActivitySession,
    required this.finishActivitySession,
    required this.abandonActivitySession,
    Stream<int> Function()? ticker,
  }) : _ticker =
           ticker ??
           (() => Stream.periodic(const Duration(seconds: 1), (x) => x + 1)),
       super(const ActivitySessionInitial()) {
    on<ActivitySessionStarted>(_onStarted);
    on<ActivitySessionTicked>(_onTicked);
    on<ActivitySessionFinished>(_onFinished);
    on<ActivitySessionAbandoned>(_onAbandoned);
  }

  Future<void> _onStarted(
    ActivitySessionStarted event,
    Emitter<ActivitySessionState> emit,
  ) async {
    emit(ActivitySessionStarting(event.activity));

    final userResult = await getCurrentUser(const NoParams());
    final user = userResult.fold((_) => null, (u) => u);

    ActivitySession? session;
    String? warning;

    if (user != null) {
      final sessionResult = await startActivitySession(
        StartActivitySessionParams(
          userId: user.id,
          activityId: event.activity.id,
        ),
      );
      sessionResult.fold(
        (_) => warning =
            'No pudimos registrar tu sesión en la nube, pero puedes continuar tu pausa con calma.',
        (createdSession) => session = createdSession,
      );
    } else {
      warning =
          'Sin sesión iniciada. Puedes continuar tu pausa con calma.';
    }

    emit(
      ActivitySessionActive(
        activity: event.activity,
        session: session,
        elapsedSeconds: 0,
        sessionWarning: warning,
      ),
    );

    await _timerSubscription?.cancel();
    _timerSubscription = _ticker().listen(
      (seconds) => add(ActivitySessionTicked(seconds)),
    );
  }

  void _onTicked(
    ActivitySessionTicked event,
    Emitter<ActivitySessionState> emit,
  ) {
    if (state is ActivitySessionActive) {
      final current = state as ActivitySessionActive;
      emit(current.copyWith(elapsedSeconds: event.elapsedSeconds));
    }
  }

  Future<void> _onFinished(
    ActivitySessionFinished event,
    Emitter<ActivitySessionState> emit,
  ) async {
    await _timerSubscription?.cancel();

    if (state is ActivitySessionActive) {
      final current = state as ActivitySessionActive;
      if (current.session != null) {
        await finishActivitySession(
          FinishActivitySessionParams(
            sessionId: current.session!.id,
            elapsedSeconds: current.elapsedSeconds,
          ),
        );
      }
      emit(
        ActivitySessionCompleted(
          activity: current.activity,
          session: current.session,
          elapsedSeconds: current.elapsedSeconds,
        ),
      );
    }
  }

  Future<void> _onAbandoned(
    ActivitySessionAbandoned event,
    Emitter<ActivitySessionState> emit,
  ) async {
    await _timerSubscription?.cancel();

    if (state is ActivitySessionActive) {
      final current = state as ActivitySessionActive;
      if (current.session != null) {
        await abandonActivitySession(
          AbandonActivitySessionParams(
            sessionId: current.session!.id,
            elapsedSeconds: current.elapsedSeconds,
          ),
        );
      }
      emit(
        ActivitySessionAbandonedState(
          activity: current.activity,
          elapsedSeconds: current.elapsedSeconds,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _timerSubscription?.cancel();
    return super.close();
  }
}
