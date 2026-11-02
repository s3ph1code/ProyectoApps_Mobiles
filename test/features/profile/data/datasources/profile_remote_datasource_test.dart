import 'dart:convert';
import 'dart:io';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:doulapp/features/profile/data/models/profile_model.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:flutter_test/flutter_test.dart';
// El cliente de Supabase recibe un `http.Client`; el paquete llega como
// dependencia de supabase_flutter y aquí solo se usa para simularlo en pruebas.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  const userId = 'uuid-1';

  final row = {
    'id': userId,
    'display_name': 'Ana',
    'avatar_url': null,
    'bio': null,
    'account_status': 'active',
    'created_at': '2026-01-10T08:00:00+00:00',
    'updated_at': '2026-01-10T08:00:00+00:00',
  };

  late http.Request? lastRequest;
  late ProfileRemoteDataSourceImpl dataSource;

  void useResponse(
    Object body, {
    int status = 200,
  }) {
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
    dataSource = ProfileRemoteDataSourceImpl(client: client);
  }

  setUp(() => lastRequest = null);

  group('createProfile', () {
    test('actualiza la fila existente con el nombre recortado', () async {
      useResponse({...row, 'display_name': 'Ana María'});

      final profile = await dataSource.createProfile(
        userId: userId,
        displayName: '  Ana María  ',
      );

      expect(lastRequest!.method, 'PATCH');
      expect(lastRequest!.url.path, '/rest/v1/profiles');
      expect(lastRequest!.url.queryParameters['id'], 'eq.$userId');
      expect(jsonDecode(lastRequest!.body), {'display_name': 'Ana María'});
      expect(profile.id, userId);
      expect(profile.displayName, 'Ana María');
    });

    test('lanza ServerException si no hay fila que actualizar', () async {
      useResponse(
        {
          'code': 'PGRST116',
          'message': 'Cannot coerce the result to a single JSON object',
        },
        status: 406,
      );

      expect(
        () => dataSource.createProfile(userId: userId, displayName: 'Ana'),
        throwsA(isA<app.ServerException>()),
      );
    });
  });

  group('getProfile', () {
    test('consulta la fila de la usuaria y la convierte en modelo', () async {
      useResponse(row);

      final profile = await dataSource.getProfile(userId);

      expect(lastRequest!.method, 'GET');
      expect(lastRequest!.url.path, '/rest/v1/profiles');
      expect(lastRequest!.url.queryParameters['id'], 'eq.$userId');
      expect(profile.displayName, 'Ana');
      expect(profile.accountStatus, AccountStatus.active);
      expect(profile.createdAt, DateTime.utc(2026, 1, 10, 8));
    });

    test('lanza ServerException cuando la fila no existe o no es visible',
        () async {
      useResponse(
        {'code': 'PGRST116', 'message': 'The result contains 0 rows'},
        status: 406,
      );

      expect(
        () => dataSource.getProfile(userId),
        throwsA(isA<app.ServerException>()),
      );
    });

    test('un fallo de conexión se convierte en NetworkException', () async {
      final client = supabase.SupabaseClient(
        'http://localhost:54321',
        'public-key',
        httpClient: MockClient(
          (_) async => throw const SocketException('sin red'),
        ),
      );
      dataSource = ProfileRemoteDataSourceImpl(client: client);

      expect(
        () => dataSource.getProfile(userId),
        throwsA(isA<app.NetworkException>()),
      );
    });
  });

  group('updateProfile', () {
    test('envía solo los campos editables, nunca account_status', () async {
      useResponse({...row, 'bio': 'Un día a la vez.'});
      final model = ProfileModel.fromJson({...row, 'bio': 'Un día a la vez.'});

      final profile = await dataSource.updateProfile(model);

      expect(lastRequest!.method, 'PATCH');
      expect(lastRequest!.url.queryParameters['id'], 'eq.$userId');
      expect(jsonDecode(lastRequest!.body), {
        'display_name': 'Ana',
        'avatar_url': null,
        'bio': 'Un día a la vez.',
      });
      expect(profile.bio, 'Un día a la vez.');
    });
  });
}
