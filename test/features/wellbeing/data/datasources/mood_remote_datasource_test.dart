import 'dart:convert';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/wellbeing/data/datasources/mood_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  late http.Request? lastRequest;
  late MoodRemoteDataSourceImpl dataSource;

  void useResponse(Object body, {int status = 200}) {
    final client = supabase.SupabaseClient(
      'http://localhost:54321',
      'public-key',
      httpClient: MockClient((request) async {
        lastRequest = request;
        return http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    dataSource = MoodRemoteDataSourceImpl(client: client);
  }

  setUp(() => lastRequest = null);

  test('inserta el check-in con el usuario, el ánimo y la nota', () async {
    useResponse({
      'id': 'c-1',
      'user_id': 'u',
      'mood_score': 4,
      'note': 'Bien',
      'recorded_at': '2026-11-10T14:30:00+00:00',
    }, status: 201);

    final checkin = await dataSource.insertCheckin(
      userId: 'u',
      moodScore: 4,
      note: 'Bien',
    );

    expect(lastRequest!.method, 'POST');
    expect(lastRequest!.url.path, '/rest/v1/mood_checkins');
    expect(jsonDecode(lastRequest!.body), {
      'user_id': 'u',
      'mood_score': 4,
      'note': 'Bien',
    });
    expect(checkin.id, 'c-1');
    expect(checkin.moodScore, 4);
  });

  test('lanza ServerException si el servidor rechaza el insert', () async {
    useResponse({
      'code': '42501',
      'message': 'new row violates row-level security policy',
    }, status: 403);

    expect(
      () => dataSource.insertCheckin(userId: 'u', moodScore: 4),
      throwsA(isA<app.ServerException>()),
    );
  });
}
