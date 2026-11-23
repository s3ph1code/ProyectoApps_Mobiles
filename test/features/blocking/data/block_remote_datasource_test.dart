import 'dart:convert';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/blocking/data/datasources/block_remote_datasource.dart';
import 'package:doulapp/features/blocking/data/models/blocked_user_model.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../fixtures.dart';

void main() {
  late http.Request? lastRequest;
  late BlockRemoteDataSourceImpl dataSource;

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
    dataSource = BlockRemoteDataSourceImpl(client: client);
  }

  setUp(() => lastRequest = null);

  group('BlockedUserModel', () {
    test('lee el nombre del perfil embebido', () {
      expect(BlockedUserModel.fromJson(blockedRow), blockedModelAna);
    });

    test('el nombre es nulo cuando el perfil es privado', () {
      final model = BlockedUserModel.fromJson(const {
        'blocked_id': 'x',
        'created_at': '2026-11-20T00:00:00+00:00',
        'blocked': null,
      });

      expect(model.displayName, isNull);
    });
  });

  test(
    'getBlockedUsers consulta solo mis bloqueos, de más nuevo a viejo',
    () async {
      useResponse([blockedRow]);

      final users = await dataSource.getBlockedUsers('me');

      expect(lastRequest!.method, 'GET');
      expect(lastRequest!.url.path, '/rest/v1/user_blocks');
      expect(lastRequest!.url.queryParameters['blocker_id'], 'eq.me');
      expect(
        lastRequest!.url.queryParameters['order'],
        startsWith('created_at.desc'),
      );
      expect(users, [blockedModelAna]);
    },
  );

  test('blockUser inserta ignorando duplicados', () async {
    useResponse([]);

    await dataSource.blockUser(blockerId: 'me', blockedId: 'ana-id');

    expect(lastRequest!.method, 'POST');
    expect(lastRequest!.url.path, '/rest/v1/user_blocks');
    expect(lastRequest!.headers['Prefer'], contains('ignore-duplicates'));
    expect(jsonDecode(lastRequest!.body), {
      'blocker_id': 'me',
      'blocked_id': 'ana-id',
    });
  });

  test('unblockUser borra solo esa pareja', () async {
    useResponse([]);

    await dataSource.unblockUser(blockerId: 'me', blockedId: 'ana-id');

    expect(lastRequest!.method, 'DELETE');
    expect(lastRequest!.url.queryParameters['blocker_id'], 'eq.me');
    expect(lastRequest!.url.queryParameters['blocked_id'], 'eq.ana-id');
  });

  test('un error de la base se vuelve ServerException', () async {
    useResponse({'code': '42501', 'message': 'denied'}, status: 403);

    expect(
      () => dataSource.getBlockedUsers('me'),
      throwsA(isA<app.ServerException>()),
    );
  });
}
