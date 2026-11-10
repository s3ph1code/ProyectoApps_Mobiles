import 'package:doulapp/features/wellbeing/data/models/mood_checkin_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson lee una fila de mood_checkins', () {
    final model = MoodCheckinModel.fromJson(const {
      'id': 'c-1',
      'user_id': 'u',
      'mood_score': 4,
      'note': 'Bien',
      'recorded_at': '2026-11-10T14:30:00+00:00',
    });

    expect(model.id, 'c-1');
    expect(model.moodScore, 4);
    expect(model.note, 'Bien');
    expect(model.recordedAt, DateTime.utc(2026, 11, 10, 14, 30));
  });

  test('la nota puede venir vacía', () {
    final model = MoodCheckinModel.fromJson(const {
      'id': 'c-2',
      'mood_score': 1,
      'note': null,
      'recorded_at': '2026-11-10T14:30:00+00:00',
    });

    expect(model.note, isNull);
  });
}
