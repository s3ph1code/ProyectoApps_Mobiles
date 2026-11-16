import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../entities/post_type.dart';
import '../entities/post_visibility.dart';
import '../repositories/community_repository.dart';

/// Publica en la comunidad. Valida antes de enviar para que la usuaria sepa
/// qué corregir sin esperar al servidor (que valida lo mismo).
class CreatePost implements UseCase<Post, CreatePostParams> {
  static const maxBodyLength = 2000;

  final CommunityRepository repository;

  CreatePost(this.repository);

  @override
  Future<Either<Failure, Post>> call(CreatePostParams params) {
    final body = params.body.trim();

    if (body.isEmpty) {
      return Future.value(const Left(EmptyPostBodyFailure()));
    }
    if (body.length > maxBodyLength) {
      return Future.value(const Left(PostBodyTooLongFailure()));
    }
    final categoryIds = params.categoryIds.toSet().toList();
    if (categoryIds.isEmpty) {
      return Future.value(const Left(PostCategoryRequiredFailure()));
    }

    return repository.createPost(
      type: params.type,
      body: body,
      visibility: params.visibility,
      categoryIds: categoryIds,
    );
  }
}

class CreatePostParams extends Equatable {
  final PostType type;
  final String body;
  final PostVisibility visibility;
  final List<String> categoryIds;

  const CreatePostParams({
    required this.type,
    required this.body,
    required this.visibility,
    required this.categoryIds,
  });

  @override
  List<Object?> get props => [type, body, visibility, categoryIds];
}
