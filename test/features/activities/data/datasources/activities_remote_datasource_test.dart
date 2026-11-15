import 'dart:convert';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/activities/data/datasources/activities_remote_datasource.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  late http.Request? lastRequest;
  late ActivitiesRemoteDataSourceImpl dataSource;

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
    dataSource = ActivitiesRemoteDataSourceImpl(client: client);
  }

  setUp(() => lastRequest = null);

  group('fetchCategories', () {
    test('consulta solo las categorías activas, por nombre', () async {
      useResponse([
        {
          'id': 'cat-2',
          'name': 'Descanso',
          'slug': 'descanso',
          'is_active': true,
        },
        {
          'id': 'cat-1',
          'name': 'Respiración',
          'slug': 'respiracion',
          'is_active': true,
        },
      ]);

      final categories = await dataSource.fetchCategories();

      expect(lastRequest!.method, 'GET');
      expect(lastRequest!.url.path, '/rest/v1/activity_categories');
      expect(lastRequest!.url.queryParameters['is_active'], 'eq.true');
      expect(lastRequest!.url.queryParameters['order'], contains('name'));
      expect(categories.map((c) => c.slug).toList(), [
        'descanso',
        'respiracion',
      ]);
    });

    test('lanza ServerException si falla', () async {
      useResponse({'code': '500', 'message': 'boom'}, status: 500);

      expect(
        () => dataSource.fetchCategories(),
        throwsA(isA<app.ServerException>()),
      );
    });
  });

  group('fetchActivities', () {
    Object oneRow() => [
      {
        'id': 'act-1',
        'category_id': 'cat-1',
        'title': 'Respiración 4-7-8',
        'description': 'Una pausa.',
        'modality': 'do',
        'duration_minutes': 3,
      },
    ];

    test('pide solo las publicadas y sin filtro de categoría', () async {
      useResponse(oneRow());

      final activities = await dataSource.fetchActivities();

      expect(lastRequest!.url.path, '/rest/v1/activities');
      expect(lastRequest!.url.queryParameters['is_published'], 'eq.true');
      expect(lastRequest!.url.queryParameters.containsKey('category_id'), isFalse);
      expect(activities.single.title, 'Respiración 4-7-8');
      expect(activities.single.modality, ActivityModality.practice);
    });

    test('con categoría agrega el filtro y conserva el de publicadas', () async {
      useResponse(oneRow());

      await dataSource.fetchActivities(categoryId: 'cat-1');

      expect(lastRequest!.url.queryParameters['category_id'], 'eq.cat-1');
      expect(lastRequest!.url.queryParameters['is_published'], 'eq.true');
    });

    test('una categoría sin actividades devuelve lista vacía', () async {
      useResponse(const []);

      expect(await dataSource.fetchActivities(categoryId: 'cat-9'), isEmpty);
    });

    test('lanza ServerException si falla', () async {
      useResponse({'code': '500', 'message': 'boom'}, status: 500);

      expect(
        () => dataSource.fetchActivities(),
        throwsA(isA<app.ServerException>()),
      );
    });
  });
}
