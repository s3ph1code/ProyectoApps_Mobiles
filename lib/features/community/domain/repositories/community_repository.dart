import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/community_category.dart';
import '../entities/post.dart';
import '../entities/post_comment.dart';
import '../entities/post_type.dart';
import '../entities/post_visibility.dart';

abstract class CommunityRepository {
  Future<Either<Failure, List<CommunityCategory>>> getCategories();

  /// Publicaciones visibles, de la más reciente a la más antigua.
  Future<Either<Failure, List<Post>>> getPosts({
    String? categoryId,
    required int offset,
    required int limit,
  });

  Future<Either<Failure, Post>> getPostById(String postId);

  /// Comentarios publicados, del más antiguo al más reciente.
  Future<Either<Failure, List<PostComment>>> getComments(String postId);

  /// Publica como la usuaria de la sesión y devuelve la publicación creada.
  Future<Either<Failure, Post>> createPost({
    required PostType type,
    required String body,
    required PostVisibility visibility,
    required List<String> categoryIds,
  });
}
