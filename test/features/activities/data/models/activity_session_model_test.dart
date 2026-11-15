import 'package:doulapp/features/activities/data/models/activity_session_model.dart';
import 'package:doulapp/features/activities/domain/entities/activity_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sessionJson = {
    'id': 'sess-1',
    'user_id': 'usr-1',
    'activity_id': 'act-1',
    'started_at': '2026-11-15T10:00:00.000Z',
    'completed_at': '2026-11-15T10:05:00.000Z',
    'status': 'completed',
    'elapsed_seconds': 300,
  };

  test('fromJson parsea correctamente todos los campos', () {
    final model = ActivitySessionModel.fromJson(sessionJson);

    expect(model.id, 'sess-1');
    expect(model.userId, 'usr-1');
    expect(model.activityId, 'act-1');
    expect(model.startedAt, DateTime.parse('2026-11-15T10:00:00.000Z'));
    expect(model.completedAt, DateTime.parse('2026-11-15T10:05:00.000Z'));
    expect(model.status, ActivitySessionStatus.completed);
    expect(model.elapsedSeconds, 300);
  });

  test('toJson serializa correctamente al formato snake_case', () {
    final model = ActivitySessionModel.fromJson(sessionJson);
    final json = model.toJson();

    expect(json['id'], 'sess-1');
    expect(json['user_id'], 'usr-1');
    expect(json['activity_id'], 'act-1');
    expect(json['status'], 'completed');
    expect(json['elapsed_seconds'], 300);
  });

  test('status desconocido defaultea a inProgress', () {
    final json = Map<String, dynamic>.from(sessionJson)..['status'] = 'unknown';
    final model = ActivitySessionModel.fromJson(json);

    expect(model.status, ActivitySessionStatus.inProgress);
  });
}
