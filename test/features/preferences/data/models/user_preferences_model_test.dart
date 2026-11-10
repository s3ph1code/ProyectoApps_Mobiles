import 'package:doulapp/features/preferences/data/models/user_preferences_model.dart';
import 'package:doulapp/features/preferences/domain/entities/profile_visibility.dart';
import 'package:doulapp/features/preferences/domain/entities/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson lee las columnas de user_preferences', () {
    final model = UserPreferencesModel.fromJson(const {
      'profile_visibility': 'private',
      'allow_notifications': false,
      'wellbeing_reminders': true,
      'language_code': 'en',
    });

    expect(model.profileVisibility, ProfileVisibility.private);
    expect(model.allowNotifications, isFalse);
    expect(model.wellbeingReminders, isTrue);
    expect(model.languageCode, 'en');
  });

  test('toJson envía solo los campos editables', () {
    const entity = UserPreferences(
      profileVisibility: ProfileVisibility.public,
      allowNotifications: true,
      wellbeingReminders: false,
      languageCode: 'es',
    );

    expect(UserPreferencesModel.fromEntity(entity).toJson(), {
      'profile_visibility': 'public',
      'allow_notifications': true,
      'wellbeing_reminders': false,
    });
  });
}
