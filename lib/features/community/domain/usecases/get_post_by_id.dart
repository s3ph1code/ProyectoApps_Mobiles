import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../repositories/community_repository.dart';

/// Una publicación por su id. Un id vacío equivale a una que no existe.
class GetPostById implements UseCase<Post, GetPostByIdParams> {
  final CommunityRepository repository;

  GetPostById(this.repository);

  @override
  Future<Either<Failure, Post>> call(GetPostByIdParams params) {
    final postId = params.postId.trim();

    if (postId.isEmpty) {
      return Future.value(const Left(PostNotFoundFailure()));
    }

    return repository.getPostById(postId);
  }
}

class GetPostByIdParams extends Equatable {
  final String postId;

  const GetPostByIdParams({required this.postId});

  @override
  List<Object?> get props => [postId];
}
