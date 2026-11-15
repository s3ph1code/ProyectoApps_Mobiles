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

  test('consulta los check-ins de la usuaria, recientes primero', () async {
    useResponse([
      {
        'id': 'c-2',
        'user_id': 'u',
        'mood_score': 2,
        'note': 'Noche larga',
        'recorded_at': '2026-11-12T08:00:00+00:00',
      },
      {
        'id': 'c-1',
        'user_id': 'u',
        'mood_score': 4,
        'note': null,
        'recorded_at': '2026-11-10T14:30:00+00:00',
      },
    ]);

    final history = await dataSource.fetchCheckins(userId: 'u', limit: 30);

    expect(lastRequest!.method, 'GET');
    expect(lastRequest!.url.path, '/rest/v1/mood_checkins');
    expect(lastRequest!.url.queryParameters['user_id'], 'eq.u');
    expect(lastRequest!.url.queryParameters['order'], contains('recorded_at'));
    expect(lastRequest!.url.queryParameters['order'], contains('desc'));
    expect(lastRequest!.url.queryParameters['limit'], '30');

    expect(history.map((c) => c.id).toList(), ['c-2', 'c-1']);
    expect(history.first.moodScore, 2);
    expect(history.first.note, 'Noche larga');
    expect(history.last.note, isNull);
  });

  test('sin registros devuelve una lista vacía', () async {
    useResponse(const []);

    expect(await dataSource.fetchCheckins(userId: 'u', limit: 30), isEmpty);
  });

  test('lanza ServerException si el servidor rechaza la consulta', () async {
    useResponse({
      'code': '42501',
      'message': 'new row violates row-level security policy',
    }, status: 403);

    expect(
      () => dataSource.fetchCheckins(userId: 'u', limit: 30),
      throwsA(isA<app.ServerException>()),
    );
  });
}
