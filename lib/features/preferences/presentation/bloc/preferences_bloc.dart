import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/get_preferences.dart';
import '../../domain/usecases/update_preferences.dart';
import 'preferences_event.dart';
import 'preferences_state.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final GetCurrentUser getCurrentUser;
  final GetPreferences getPreferences;
  final UpdatePreferences updatePreferences;

  String? _userId;

  PreferencesBloc({
    required this.getCurrentUser,
    required this.getPreferences,
    required this.updatePreferences,
  }) : super(const PreferencesInitial()) {
    on<PreferencesLoadRequested>(_onLoadRequested);
    on<PreferencesVisibilityChanged>(
      (event, emit) => _save(
        emit,
        (prefs) => prefs.copyWith(profileVisibility: event.visibility),
      ),
    );
    on<PreferencesNotificationsChanged>(
      (event, emit) => _save(
        emit,
        (prefs) => prefs.copyWith(allowNotifications: event.enabled),
      ),
    );
    on<PreferencesRemindersChanged>(
      (event, emit) => _save(
        emit,
        (prefs) => prefs.copyWith(wellbeingReminders: event.enabled),
      ),
    );
  }

  Future<void> _onLoadRequested(
    PreferencesLoadRequested event,
    Emitter<PreferencesState> emit,
  ) async {
    emit(const PreferencesLoading());

    final userResult = await getCurrentUser(const NoParams());
    await userResult.fold(
      (failure) async => emit(PreferencesFailure(failure.message)),
      (user) async {
        if (user == null) {
          emit(PreferencesFailure(const UnauthenticatedFailure().message));
          return;
        }

        _userId = user.id;
        final result = await getPreferences(
          GetPreferencesParams(userId: user.id),
        );
        result.fold(
          (failure) => emit(PreferencesFailure(failure.message)),
          (preferences) => emit(PreferencesLoaded(preferences: preferences)),
        );
      },
    );
  }

  /// Guarda al instante: la pantalla ya muestra el valor nuevo y, si el
  /// guardado falla, el control vuelve al valor anterior con un aviso.
  Future<void> _save(
    Emitter<PreferencesState> emit,
    UserPreferences Function(UserPreferences current) change,
  ) async {
    final current = state;
    final userId = _userId;
    if (current is! PreferencesLoaded || current.isSaving || userId == null) {
      return;
    }

    final next = change(current.preferences);
    if (next == current.preferences) return;

    emit(PreferencesLoaded(preferences: next, isSaving: true));

    final result = await updatePreferences(
      UpdatePreferencesParams(userId: userId, preferences: next),
    );

    result.fold(
      (failure) => emit(
        PreferencesLoaded(
          preferences: current.preferences,
          errorMessage: failure.message,
        ),
      ),
      (saved) => emit(PreferencesLoaded(preferences: saved)),
    );
  }
}
