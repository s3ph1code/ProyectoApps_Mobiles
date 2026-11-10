import 'package:equatable/equatable.dart';

import 'profile_visibility.dart';

/// Preferencias de la cuenta: privacidad y avisos. 1:1 con la usuaria.
class UserPreferences extends Equatable {
  final ProfileVisibility profileVisibility;
  final bool allowNotifications;
  final bool wellbeingReminders;
  final String languageCode;

  const UserPreferences({
    required this.profileVisibility,
    required this.allowNotifications,
    required this.wellbeingReminders,
    required this.languageCode,
  });

  UserPreferences copyWith({
    ProfileVisibility? profileVisibility,
    bool? allowNotifications,
    bool? wellbeingReminders,
  }) {
    return UserPreferences(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      allowNotifications: allowNotifications ?? this.allowNotifications,
      wellbeingReminders: wellbeingReminders ?? this.wellbeingReminders,
      languageCode: languageCode,
    );
  }

  @override
  List<Object?> get props => [
    profileVisibility,
    allowNotifications,
    wellbeingReminders,
    languageCode,
  ];
}
