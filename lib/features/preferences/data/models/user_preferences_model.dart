import '../../domain/entities/profile_visibility.dart';
import '../../domain/entities/user_preferences.dart';

class UserPreferencesModel extends UserPreferences {
  const UserPreferencesModel({
    required super.profileVisibility,
    required super.allowNotifications,
    required super.wellbeingReminders,
    required super.languageCode,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      profileVisibility: ProfileVisibility.fromCode(
        json['profile_visibility'] as String,
      ),
      allowNotifications: json['allow_notifications'] as bool,
      wellbeingReminders: json['wellbeing_reminders'] as bool,
      languageCode: (json['language_code'] as String?) ?? 'es',
    );
  }

  factory UserPreferencesModel.fromEntity(UserPreferences preferences) {
    return UserPreferencesModel(
      profileVisibility: preferences.profileVisibility,
      allowNotifications: preferences.allowNotifications,
      wellbeingReminders: preferences.wellbeingReminders,
      languageCode: preferences.languageCode,
    );
  }

  /// Solo los campos que la usuaria puede cambiar; el idioma no se edita aún.
  Map<String, dynamic> toJson() => {
    'profile_visibility': profileVisibility.code,
    'allow_notifications': allowNotifications,
    'wellbeing_reminders': wellbeingReminders,
  };
}
