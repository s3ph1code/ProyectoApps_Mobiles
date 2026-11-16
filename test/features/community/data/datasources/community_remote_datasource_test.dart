import 'dart:convert';

import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/community/data/datasources/community_remote_datasource.dart';
import 'package:doulapp/features/community/domain/entities/post_type.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  late http.Request? lastRequest;
  late CommunityRemoteDataSourceImpl dataSource;

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
    dataSource = CommunityRemoteDataSourceImpl(client: client);
  }

  Map<String, dynamic> feedRow(String id) => {
    'id': id,
    'author_id': 'author-1',
    'author_name': 'Ana',
    'author_avatar_url': null,
    'post_type': 'question',
    'body': 'De noche todo pesa más.',
    'visibility': 'community',
    'status': 'published',
    'created_at': '2026-11-10T15:00:00+00:00',
    'updated_at': '2026-11-10T15:00:00+00:00',
    'categories': [
      {'id': 'cat-1', 'name': 'Emociones', 'slug': 'emociones'},
    ],
    'category_ids': ['cat-1'],
    'reaction_count': 4,
    'comment_count': 2,
  };

  setUp(() => lastRequest = null);

  group('fetchCategories', () {
    test('pide solo las activas, por nombre', () async {
      useResponse([
        {'id': 'cat-1', 'name': 'Emociones', 'slug': 'emociones'},
      ]);

      final categories = await dataSource.fetchCategories();

      expect(lastRequest!.url.path, '/rest/v1/community_categories');
      expect(lastRequest!.url.queryParameters['is_active'], 'eq.true');
      expect(lastRequest!.url.queryParameters['order'], contains('name'));
      expect(categories.single.slug, 'emociones');
    });
  });

  group('fetchPosts', () {
    test(
      'lee la vista del feed, solo publicadas y las más recientes primero',
      () async {
        useResponse([feedRow('p1')]);

        final posts = await dataSource.fetchPosts(offset: 0, limit: 20);

        final query = lastRequest!.url.queryParameters;
        expect(lastRequest!.url.path, '/rest/v1/post_feed');
        expect(query['status'], 'eq.published');
        expect(query['order'], 'created_at.desc.nullslast');
        expect(query['offset'], '0');
        expect(query['limit'], '20');
        expect(query.containsKey('category_ids'), isFalse);

        final post = posts.single;
        expect(post.type, PostType.question);
        expect(post.authorName, 'Ana');
        expect(post.categories.single.name, 'Emociones');
        expect(post.reactionCount, 4);
        expect(post.commentCount, 2);
      },
    );

    test('filtra por categoría y pide la página indicada', () async {
      useResponse([]);

      await dataSource.fetchPosts(categoryId: 'cat-1', offset: 20, limit: 20);

      final query = lastRequest!.url.queryParameters;
      expect(query['category_ids'], 'cs.{"cat-1"}');
      expect(query['offset'], '20');
      expect(query['limit'], '20');
    });

    test('lanza ServerException si falla', () async {
      useResponse({'code': '500', 'message': 'boom'}, status: 500);

      expect(
        () => dataSource.fetchPosts(offset: 0, limit: 20),
        throwsA(isA<app.ServerException>()),
      );
    });
  });

  group('fetchPostById', () {
    test('busca la publicada con ese id', () async {
      useResponse([feedRow('p9')]);

      final post = await dataSource.fetchPostById('p9');

      expect(lastRequest!.url.queryParameters['id'], 'eq.p9');
      expect(lastRequest!.url.queryParameters['status'], 'eq.published');
      expect(post.id, 'p9');
    });

    test('sin filas lanza NotFoundException', () async {
      useResponse([]);

      expect(
        () => dataSource.fetchPostById('nada'),
        throwsA(isA<app.NotFoundException>()),
      );
    });
  });

  group('fetchComments', () {
    test(
      'pide los publicados de la publicación con la autora embebida',
      () async {
        useResponse([
          {
            'id': 'c1',
            'post_id': 'p1',
            'author_id': 'author-2',
            'parent_comment_id': null,
            'body': 'Te leo.',
            'created_at': '2026-11-10T16:00:00+00:00',
            'author': {'display_name': 'Bea'},
          },
          {
            'id': 'c2',
            'post_id': 'p1',
            'author_id': 'author-3',
            'parent_comment_id': 'c1',
            'body': 'Igual yo.',
            'created_at': '2026-11-10T16:05:00+00:00',
            'author': null,
          },
        ]);

        final comments = await dataSource.fetchComments('p1');

        final query = lastRequest!.url.queryParameters;
        expect(lastRequest!.url.path, '/rest/v1/comments');
        expect(query['post_id'], 'eq.p1');
        expect(query['status'], 'eq.published');
        expect(query['select'], contains('author:profiles(display_name)'));
        expect(comments.first.authorName, 'Bea');
        expect(comments.last.authorName, isNull);
        expect(comments.last.parentCommentId, 'c1');
      },
    );
  });

  group('createPost', () {
    test('llama a create_post con todos los datos y devuelve el id', () async {
      useResponse('nuevo-id');

      final id = await dataSource.createPost(
        postType: 'experience',
        body: 'Hoy salí a caminar.',
        visibility: 'public',
        categoryIds: ['cat-1', 'cat-2'],
      );

      expect(lastRequest!.method, 'POST');
      expect(lastRequest!.url.path, '/rest/v1/rpc/create_post');
      expect(jsonDecode(lastRequest!.body), {
        'p_post_type': 'experience',
        'p_body': 'Hoy salí a caminar.',
        'p_visibility': 'public',
        'p_category_ids': ['cat-1', 'cat-2'],
      });
      expect(id, 'nuevo-id');
    });

    test(
      'si el servidor rechaza la publicación lanza ServerException',
      () async {
        useResponse({
          'code': 'P0001',
          'message': 'Elige al menos una categoría',
        }, status: 400);

        expect(
          () => dataSource.createPost(
            postType: 'message',
            body: 'Hola',
            visibility: 'community',
            categoryIds: const [],
          ),
          throwsA(isA<app.ServerException>()),
        );
      },
    );
  });
}
