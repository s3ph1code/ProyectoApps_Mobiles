import 'package:equatable/equatable.dart';

import '../../domain/entities/user_preferences.dart';

sealed class PreferencesState extends Equatable {
  const PreferencesState();

  @override
  List<Object?> get props => [];
}

class PreferencesInitial extends PreferencesState {
  const PreferencesInitial();
}

class PreferencesLoading extends PreferencesState {
  const PreferencesLoading();
}

/// Preferencias cargadas. Mientras se guarda un cambio, [preferences] ya
/// muestra el valor nuevo y [isSaving] es `true`. Si el guardado falla,
/// vuelve el valor anterior y [errorMessage] explica qué pasó.
class PreferencesLoaded extends PreferencesState {
  final UserPreferences preferences;
  final bool isSaving;
  final String? errorMessage;

  const PreferencesLoaded({
    required this.preferences,
    this.isSaving = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [preferences, isSaving, errorMessage];
}

/// No se pudieron cargar las preferencias.
class PreferencesFailure extends PreferencesState {
  final String message;

  const PreferencesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
