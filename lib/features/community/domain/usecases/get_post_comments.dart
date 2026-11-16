import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post_comment.dart';
import '../repositories/community_repository.dart';

/// Los comentarios de una publicación, listos para leerse en orden: cada
/// comentario seguido de sus respuestas.
class GetPostComments
    implements UseCase<List<PostComment>, GetPostCommentsParams> {
  final CommunityRepository repository;

  GetPostComments(this.repository);

  @override
  Future<Either<Failure, List<PostComment>>> call(
    GetPostCommentsParams params,
  ) async {
    final result = await repository.getComments(params.postId);
    return result.map(threadComments);
  }

  /// Ordena los comentarios como conversación. Una respuesta cuyo comentario
  /// original no llegó (oculto, o de alguien bloqueado) se muestra suelta en
  /// lugar de perderse.
  static List<PostComment> threadComments(List<PostComment> comments) {
    final byDate = [...comments]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final ids = byDate.map((c) => c.id).toSet();

    final roots = byDate
        .where((c) => !c.isReply || !ids.contains(c.parentCommentId))
        .toList();
    final replies = <String, List<PostComment>>{};
    for (final comment in byDate) {
      final parent = comment.parentCommentId;
      if (parent != null && ids.contains(parent)) {
        replies.putIfAbsent(parent, () => []).add(comment);
      }
    }

    final ordered = <PostComment>[];
    void addWithReplies(PostComment comment) {
      ordered.add(comment);
      for (final reply in replies[comment.id] ?? const <PostComment>[]) {
        addWithReplies(reply);
      }
    }

    roots.forEach(addWithReplies);
    return ordered;
  }
}

class GetPostCommentsParams extends Equatable {
  final String postId;

  const GetPostCommentsParams({required this.postId});

  @override
  List<Object?> get props => [postId];
}
