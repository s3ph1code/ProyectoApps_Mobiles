import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/community_category_model.dart';
import '../models/post_comment_model.dart';
import '../models/post_model.dart';

abstract class CommunityRemoteDataSource {
  Future<List<CommunityCategoryModel>> fetchCategories();

  Future<List<PostModel>> fetchPosts({
    String? categoryId,
    required int offset,
    required int limit,
  });

  /// Lanza [NotFoundException] si la publicación no existe o no es visible.
  Future<PostModel> fetchPostById(String postId);

  Future<List<PostCommentModel>> fetchComments(String postId);

  /// Devuelve el id de la publicación creada.
  Future<String> createPost({
    required String postType,
    required String body,
    required String visibility,
    required List<String> categoryIds,
  });
}

class CommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final supabase.SupabaseClient client;

  CommunityRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CommunityCategoryModel>> fetchCategories() {
    return _guard(() async {
      final rows = await client
          .from('community_categories')
          .select('id, name, slug')
          .eq('is_active', true)
          .order('name', ascending: true);

      return rows.map(CommunityCategoryModel.fromJson).toList();
    });
  }

  /// Filtra `status = published` de forma explícita y no solo por RLS: la
  /// autora y la moderación también ven lo oculto, y en el feed no debe salir.
  @override
  Future<List<PostModel>> fetchPosts({
    String? categoryId,
    required int offset,
    required int limit,
  }) {
    return _guard(() async {
      var query = client.from('post_feed').select().eq('status', 'published');

      if (categoryId != null) {
        query = query.contains('category_ids', [categoryId]);
      }

      final rows = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return rows.map(PostModel.fromJson).toList();
    });
  }

  @override
  Future<PostModel> fetchPostById(String postId) {
    return _guard(() async {
      final rows = await client
          .from('post_feed')
          .select()
          .eq('id', postId)
          .eq('status', 'published')
          .limit(1);

      if (rows.isEmpty) throw const NotFoundException();

      return PostModel.fromJson(rows.first);
    });
  }

  @override
  Future<List<PostCommentModel>> fetchComments(String postId) {
    return _guard(() async {
      final rows = await client
          .from('comments')
          .select(
            'id, post_id, author_id, parent_comment_id, body, created_at, '
            'author:profiles(display_name)',
          )
          .eq('post_id', postId)
          .eq('status', 'published')
          .order('created_at', ascending: true);

      return rows.map(PostCommentModel.fromJson).toList();
    });
  }

  /// Va por la función `create_post` para que la publicación y sus
  /// categorías se guarden juntas o no se guarde nada.
  @override
  Future<String> createPost({
    required String postType,
    required String body,
    required String visibility,
    required List<String> categoryIds,
  }) {
    return _guard(() async {
      final id = await client.rpc(
        'create_post',
        params: {
          'p_post_type': postType,
          'p_body': body,
          'p_visibility': visibility,
          'p_category_ids': categoryIds,
        },
      );

      if (id is! String) {
        throw const FormatException('create_post no devolvió un id.');
      }
      return id;
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.code ?? e.statusCode);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado.');
    } on FormatException catch (e) {
      throw ServerException(e.message);
    }
  }
}
