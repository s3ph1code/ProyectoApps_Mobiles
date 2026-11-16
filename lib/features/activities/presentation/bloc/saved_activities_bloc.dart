import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/entities/activity.dart';
import '../../domain/usecases/get_saved_activities.dart';
import '../../domain/usecases/save_activity.dart';
import '../../domain/usecases/unsave_activity.dart';
import 'saved_activities_event.dart';
import 'saved_activities_state.dart';

class SavedActivitiesBloc
    extends Bloc<SavedActivitiesEvent, SavedActivitiesState> {
  final GetCurrentUser getCurrentUser;
  final GetSavedActivities getSavedActivities;
  final SaveActivity saveActivity;
  final UnsaveActivity unsaveActivity;

  SavedActivitiesBloc({
    required this.getCurrentUser,
    required this.getSavedActivities,
    required this.saveActivity,
    required this.unsaveActivity,
  }) : super(const SavedActivitiesInitial()) {
    on<SavedActivitiesRequested>(_onRequested);
    on<ActivitySaveToggled>(_onSaveToggled);
    on<SavedActivitiesNoticeDismissed>(_onNoticeDismissed);
  }

  Future<void> _onRequested(
    SavedActivitiesRequested event,
    Emitter<SavedActivitiesState> emit,
  ) async {
    emit(const SavedActivitiesLoading());

    final userResult = await getCurrentUser(const NoParams());
    final user = userResult.fold((_) => null, (u) => u);
    if (user == null) {
      emit(
        const SavedActivitiesFailure(
          'Inicia sesión para consultar tus actividades guardadas.',
        ),
      );
      return;
    }

    final result = await getSavedActivities(
      GetSavedActivitiesParams(userId: user.id),
    );

    result.fold(
      (failure) => emit(SavedActivitiesFailure(_errorMessage(failure))),
      (activities) => emit(
        SavedActivitiesLoaded(
          activities: activities,
          savedIds: activities.map((a) => a.id).toSet(),
        ),
      ),
    );
  }

  Future<void> _onSaveToggled(
    ActivitySaveToggled event,
    Emitter<SavedActivitiesState> emit,
  ) async {
    final userResult = await getCurrentUser(const NoParams());
    final user = userResult.fold((_) => null, (u) => u);
    if (user == null) {
      if (state is SavedActivitiesLoaded) {
        final current = state as SavedActivitiesLoaded;
        emit(
          current.copyWith(
            noticeMessage: () => 'Inicia sesión para guardar actividades.',
          ),
        );
      }
      return;
    }

    final currentState = state;
    final currentActivities = currentState is SavedActivitiesLoaded
        ? currentState.activities
        : <Activity>[];
    final currentIds = currentState is SavedActivitiesLoaded
        ? currentState.savedIds
        : <String>{};

    final isCurrentlySaved = currentIds.contains(event.activity.id);

    if (isCurrentlySaved) {
      // Actualización optimista: quitar
      final newIds = Set<String>.from(currentIds)..remove(event.activity.id);
      final newActivities = currentActivities
          .where((a) => a.id != event.activity.id)
          .toList();

      emit(
        SavedActivitiesLoaded(
          activities: newActivities,
          savedIds: newIds,
          noticeMessage: null,
        ),
      );

      final result = await unsaveActivity(
        UnsaveActivityParams(
          userId: user.id,
          activityId: event.activity.id,
        ),
      );

      result.fold(
        (failure) {
          // Reversión al estado anterior con aviso
          emit(
            SavedActivitiesLoaded(
              activities: currentActivities,
              savedIds: currentIds,
              noticeMessage: 'No pudimos quitar la actividad. Inténtalo de nuevo.',
            ),
          );
        },
        (_) {},
      );
    } else {
      // Actualización optimista: guardar
      final newIds = Set<String>.from(currentIds)..add(event.activity.id);
      final newActivities = [event.activity, ...currentActivities];

      emit(
        SavedActivitiesLoaded(
          activities: newActivities,
          savedIds: newIds,
          noticeMessage: null,
        ),
      );

      final result = await saveActivity(
        SaveActivityParams(
          userId: user.id,
          activityId: event.activity.id,
        ),
      );

      result.fold(
        (failure) {
          // Reversión al estado anterior con aviso
          emit(
            SavedActivitiesLoaded(
              activities: currentActivities,
              savedIds: currentIds,
              noticeMessage: 'No pudimos guardar la actividad. Inténtalo de nuevo.',
            ),
          );
        },
        (_) {},
      );
    }
  }

  void _onNoticeDismissed(
    SavedActivitiesNoticeDismissed event,
    Emitter<SavedActivitiesState> emit,
  ) {
    if (state is SavedActivitiesLoaded) {
      final current = state as SavedActivitiesLoaded;
      emit(current.copyWith(noticeMessage: () => null));
    }
  }

  String _errorMessage(Failure failure) => switch (failure) {
    NetworkFailure() =>
      'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.',
    UnauthenticatedFailure() =>
      'Inicia sesión para consultar tus actividades guardadas.',
    _ => 'Algo salió mal al consultar las actividades guardadas.',
  };
}
