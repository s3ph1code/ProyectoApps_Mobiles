import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_visibility.dart';

sealed class PreferencesEvent extends Equatable {
  const PreferencesEvent();

  @override
  List<Object?> get props => [];
}

class PreferencesLoadRequested extends PreferencesEvent {
  const PreferencesLoadRequested();
}

class PreferencesVisibilityChanged extends PreferencesEvent {
  final ProfileVisibility visibility;

  const PreferencesVisibilityChanged(this.visibility);

  @override
  List<Object?> get props => [visibility];
}

class PreferencesNotificationsChanged extends PreferencesEvent {
  final bool enabled;

  const PreferencesNotificationsChanged(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class PreferencesRemindersChanged extends PreferencesEvent {
  final bool enabled;

  const PreferencesRemindersChanged(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
