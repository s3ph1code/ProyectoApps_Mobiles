import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/community_category.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_comment.dart';
import '../../domain/entities/post_type.dart';
import '../../domain/entities/post_visibility.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_remote_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;

  CommunityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CommunityCategory>>> getCategories() {
    return _guard(remoteDataSource.fetchCategories);
  }

  @override
  Future<Either<Failure, List<Post>>> getPosts({
    String? categoryId,
    required int offset,
    required int limit,
  }) {
    return _guard(
      () => remoteDataSource.fetchPosts(
        categoryId: categoryId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<Either<Failure, Post>> getPostById(String postId) {
    return _guard(() => remoteDataSource.fetchPostById(postId));
  }

  @override
  Future<Either<Failure, List<PostComment>>> getComments(String postId) {
    return _guard(() => remoteDataSource.fetchComments(postId));
  }

  @override
  Future<Either<Failure, Post>> createPost({
    required PostType type,
    required String body,
    required PostVisibility visibility,
    required List<String> categoryIds,
  }) {
    return _guard(() async {
      final id = await remoteDataSource.createPost(
        postType: type.code,
        body: body,
        visibility: visibility.code,
        categoryIds: categoryIds,
      );
      return remoteDataSource.fetchPostById(id);
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on NotFoundException {
      return const Left(PostNotFoundFailure());
    } on UnauthenticatedException {
      return const Left(UnauthenticatedFailure());
    } on AuthException {
      return const Left(UnauthenticatedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
