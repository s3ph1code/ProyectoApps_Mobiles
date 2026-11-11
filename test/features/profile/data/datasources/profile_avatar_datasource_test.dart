import 'dart:convert';
import 'dart:typed_data';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  const userId = 'uuid-1';
  const oldUrl =
      'http://localhost:54321/storage/v1/object/public/avatars/uuid-1/1.png';

  Map<String, dynamic> row(String? avatarUrl) => {
    'id': userId,
    'display_name': 'Ana',
    'avatar_url': avatarUrl,
    'bio': null,
    'account_status': 'active',
    'created_at': '2026-01-10T08:00:00+00:00',
    'updated_at': '2026-01-10T08:00:00+00:00',
  };

  late List<http.Request> requests;
  late ProfileRemoteDataSourceImpl dataSource;

  /// Responde según la ruta: Storage devuelve éxito (o [storageStatus]) y la
  /// tabla `profiles` devuelve la fila actualizada.
  void useServer({int storageStatus = 200, bool failDelete = false}) {
    requests = [];
    final client = supabase.SupabaseClient(
      'http://localhost:54321',
      'public-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        const headers = {'content-type': 'application/json; charset=utf-8'};
        if (request.url.path.startsWith('/storage/')) {
          if (request.method == 'DELETE' && failDelete) {
            return http.Response(
              jsonEncode({'message': 'boom'}),
              500,
              request: request,
              headers: headers,
            );
          }
          return http.Response(
            jsonEncode(
              request.method == 'DELETE'
                  ? <dynamic>[]
                  : {'Key': 'avatars/x', 'message': 'ok'},
            ),
            storageStatus,
            request: request,
            headers: headers,
          );
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(row(body['avatar_url'] as String?)),
          200,
          request: request,
          headers: headers,
        );
      }),
    );
    dataSource = ProfileRemoteDataSourceImpl(client: client);
  }

  final bytes = Uint8List.fromList([1, 2, 3]);

  group('uploadAvatar', () {
    test('sube a la carpeta de la usuaria y guarda la URL pública', () async {
      useServer();

      final profile = await dataSource.uploadAvatar(
        userId: userId,
        bytes: bytes,
        mimeType: 'image/png',
        previousAvatarUrl: oldUrl,
      );

      final upload = requests.firstWhere((r) => r.method == 'POST');
      expect(
        upload.url.path,
        matches(RegExp(r'^/storage/v1/object/avatars/uuid-1/\d+\.png$')),
      );
      expect(upload.body, contains('content-type: image/png'));

      final patch = requests.firstWhere((r) => r.method == 'PATCH');
      expect(patch.url.path, '/rest/v1/profiles');
      expect(patch.url.queryParameters['id'], 'eq.$userId');
      final savedUrl = jsonDecode(patch.body)['avatar_url'] as String;
      expect(savedUrl, contains('/avatars/uuid-1/'));
      expect(savedUrl, endsWith('.png'));
      expect(profile.avatarUrl, savedUrl);
    });

    test('borra la foto anterior de la misma carpeta', () async {
      useServer();

      await dataSource.uploadAvatar(
        userId: userId,
        bytes: bytes,
        mimeType: 'image/jpeg',
        previousAvatarUrl: oldUrl,
      );

      final delete = requests.firstWhere((r) => r.method == 'DELETE');
      expect(jsonDecode(delete.body), {
        'prefixes': ['uuid-1/1.png'],
      });
    });

    test('no borra nada que esté fuera de su carpeta', () async {
      useServer();

      await dataSource.uploadAvatar(
        userId: userId,
        bytes: bytes,
        mimeType: 'image/webp',
        previousAvatarUrl:
            'http://localhost:54321/storage/v1/object/public/avatars/otra/1.png',
      );

      expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test('sin foto anterior no intenta borrar', () async {
      useServer();

      await dataSource.uploadAvatar(
        userId: userId,
        bytes: bytes,
        mimeType: 'image/png',
      );

      expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test('si falla borrar la anterior, la subida igual termina bien', () async {
      useServer(failDelete: true);

      final profile = await dataSource.uploadAvatar(
        userId: userId,
        bytes: bytes,
        mimeType: 'image/png',
        previousAvatarUrl: oldUrl,
      );

      expect(profile.avatarUrl, isNotNull);
    });

    test('lanza ServerException si Storage rechaza la imagen', () async {
      useServer(storageStatus: 413);

      expect(
        () => dataSource.uploadAvatar(
          userId: userId,
          bytes: bytes,
          mimeType: 'image/png',
        ),
        throwsA(isA<app.ServerException>()),
      );
    });

    test('si Storage falla no toca el perfil', () async {
      useServer(storageStatus: 403);

      await expectLater(
        dataSource.uploadAvatar(
          userId: userId,
          bytes: bytes,
          mimeType: 'image/png',
        ),
        throwsA(isA<app.ServerException>()),
      );
      expect(requests.where((r) => r.method == 'PATCH'), isEmpty);
    });
  });

  group('removeAvatar', () {
    test('deja avatar_url en null y borra el archivo', () async {
      useServer();

      final profile = await dataSource.removeAvatar(
        userId: userId,
        previousAvatarUrl: oldUrl,
      );

      final patch = requests.firstWhere((r) => r.method == 'PATCH');
      expect(jsonDecode(patch.body), {'avatar_url': null});
      expect(profile.avatarUrl, isNull);
      expect(requests.where((r) => r.method == 'DELETE'), hasLength(1));
    });
  });
}
