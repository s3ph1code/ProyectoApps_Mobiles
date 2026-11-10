import 'dart:convert';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:doulapp/features/preferences/data/models/user_preferences_model.dart';
import 'package:doulapp/features/preferences/domain/entities/profile_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  const userId = 'uuid-1';
  final row = {
    'user_id': userId,
    'profile_visibility': 'community',
    'allow_notifications': true,
    'wellbeing_reminders': true,
    'language_code': 'es',
  };

  late http.Request? lastRequest;
  late PreferencesRemoteDataSourceImpl dataSource;

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
    dataSource = PreferencesRemoteDataSourceImpl(client: client);
  }

  setUp(() => lastRequest = null);

  test('getPreferences consulta la fila de la usuaria', () async {
    useResponse(row);

    final prefs = await dataSource.getPreferences(userId);

    expect(lastRequest!.method, 'GET');
    expect(lastRequest!.url.path, '/rest/v1/user_preferences');
    expect(lastRequest!.url.queryParameters['user_id'], 'eq.$userId');
    expect(prefs.profileVisibility, ProfileVisibility.community);
  });

  test('getPreferences lanza ServerException si no hay fila', () async {
    useResponse({
      'code': 'PGRST116',
      'message': 'The result contains 0 rows',
    }, status: 406);

    expect(
      () => dataSource.getPreferences(userId),
      throwsA(isA<app.ServerException>()),
    );
  });

  test('updatePreferences hace PATCH con los tres campos editables', () async {
    useResponse({...row, 'profile_visibility': 'private'});

    final saved = await dataSource.updatePreferences(
      userId,
      const UserPreferencesModel(
        profileVisibility: ProfileVisibility.private,
        allowNotifications: true,
        wellbeingReminders: true,
        languageCode: 'es',
      ),
    );

    expect(lastRequest!.method, 'PATCH');
    expect(lastRequest!.url.queryParameters['user_id'], 'eq.$userId');
    expect(jsonDecode(lastRequest!.body), {
      'profile_visibility': 'private',
      'allow_notifications': true,
      'wellbeing_reminders': true,
    });
    expect(saved.profileVisibility, ProfileVisibility.private);
  });
}
