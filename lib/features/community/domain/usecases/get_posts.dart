import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../repositories/community_repository.dart';

/// Una página del feed. Una categoría vacía o en blanco significa «Todas».
class GetPosts implements UseCase<List<Post>, GetPostsParams> {
  static const pageSize = 20;

  final CommunityRepository repository;

  GetPosts(this.repository);

  @override
  Future<Either<Failure, List<Post>>> call(GetPostsParams params) {
    final categoryId = params.categoryId?.trim();

    return repository.getPosts(
      categoryId: (categoryId == null || categoryId.isEmpty)
          ? null
          : categoryId,
      offset: params.offset < 0 ? 0 : params.offset,
      limit: pageSize,
    );
  }
}

class GetPostsParams extends Equatable {
  final String? categoryId;

  /// Cuántas publicaciones ya se mostraron; la página empieza ahí.
  final int offset;

  const GetPostsParams({this.categoryId, this.offset = 0});

  @override
  List<Object?> get props => [categoryId, offset];
}
