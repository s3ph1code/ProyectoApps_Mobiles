import 'dart:convert';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/wellbeing/data/datasources/needs_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  late List<http.Request> requests;
  late NeedsRemoteDataSourceImpl dataSource;

  /// Responde cada petición en orden con [bodies]; la última se repite si
  /// llegan más.
  void useResponses(List<Object> bodies, {int status = 200}) {
    var index = 0;
    final client = supabase.SupabaseClient(
      'http://localhost:54321',
      'public-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final body = bodies[index < bodies.length ? index : bodies.length - 1];
        index++;
        return http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    dataSource = NeedsRemoteDataSourceImpl(client: client);
  }

  setUp(() => requests = []);

  group('fetchNeedOptions', () {
    test('trae solo las opciones activas', () async {
      useResponses([
        [
          {
            'id': 'opt-1',
            'code': 'cansancio',
            'label': 'Estoy muy cansada',
            'is_active': true,
          },
        ],
      ]);

      final options = await dataSource.fetchNeedOptions();

      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/rest/v1/need_options');
      expect(requests.single.url.queryParameters['is_active'], 'eq.true');
      expect(options.single.code, 'cansancio');
      expect(options.single.label, 'Estoy muy cansada');
    });

    test('lanza ServerException si falla', () async {
      useResponses([
        {'code': '500', 'message': 'boom'},
      ], status: 500);

      expect(
        () => dataSource.fetchNeedOptions(),
        throwsA(isA<app.ServerException>()),
      );
    });
  });

  group('fetchRecommendations', () {
    test('filtra por las opciones elegidas y ordena por prioridad', () async {
      useResponses([
        [
          {
            'id': 'rec-1',
            'need_option_id': 'opt-1',
            'activity_id': 'act-1',
            'destination_code': 'activities',
            'message': 'Una pausa corta puede ayudarte.',
            'priority': 10,
          },
          {
            'id': 'rec-2',
            'need_option_id': 'opt-1',
            'activity_id': null,
            'destination_code': 'mood_checkin',
            'message': 'Contarte cómo te sientes también cuenta.',
            'priority': 20,
          },
        ],
      ]);

      final recs = await dataSource.fetchRecommendations(
        optionIds: ['opt-1', 'opt-2'],
      );

      expect(requests.single.url.path, '/rest/v1/need_recommendations');
      expect(
        requests.single.url.queryParameters['need_option_id'],
        contains('opt-1'),
      );
      expect(
        requests.single.url.queryParameters['need_option_id'],
        contains('opt-2'),
      );
      expect(
        requests.single.url.queryParameters['order'],
        contains('priority'),
      );

      expect(recs.map((r) => r.id).toList(), ['rec-1', 'rec-2']);
      expect(recs.first.activityId, 'act-1');
      expect(recs.first.destinationCode, 'activities');
      expect(recs.last.activityId, isNull);
      expect(recs.last.priority, 20);
    });

    test('sin recomendaciones devuelve lista vacía', () async {
      useResponses([const []]);

      expect(
        await dataSource.fetchRecommendations(optionIds: ['opt-9']),
        isEmpty,
      );
    });
  });

  group('insertNeedSession', () {
    test('crea la sesión y luego guarda las opciones elegidas', () async {
      useResponses([
        {'id': 'sess-1', 'user_id': 'u'},
        const [],
      ], status: 201);

      final sessionId = await dataSource.insertNeedSession(
        userId: 'u',
        optionIds: ['opt-1', 'opt-2'],
      );

      expect(sessionId, 'sess-1');
      expect(requests, hasLength(2));

      expect(requests.first.url.path, '/rest/v1/need_sessions');
      expect(jsonDecode(requests.first.body), {'user_id': 'u'});

      expect(requests.last.url.path, '/rest/v1/need_session_options');
      expect(jsonDecode(requests.last.body), [
        {'need_session_id': 'sess-1', 'need_option_id': 'opt-1'},
        {'need_session_id': 'sess-1', 'need_option_id': 'opt-2'},
      ]);
    });

    test('lanza ServerException si la RLS rechaza el insert', () async {
      useResponses([
        {'code': '42501', 'message': 'row-level security'},
      ], status: 403);

      expect(
        () => dataSource.insertNeedSession(userId: 'u', optionIds: ['opt-1']),
        throwsA(isA<app.ServerException>()),
      );
    });
  });
}
