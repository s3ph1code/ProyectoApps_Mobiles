import 'package:equatable/equatable.dart';

/// Un comentario publicado, o la respuesta a otro comentario.
class PostComment extends Equatable {
  final String id;
  final String postId;
  final String authorId;

  /// `null` cuando la autora tiene el perfil privado o ya no existe.
  final String? authorName;
  final String? parentCommentId;
  final String body;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorName,
    this.parentCommentId,
    required this.body,
    required this.createdAt,
  });

  bool get isReply => parentCommentId != null;

  @override
  List<Object?> get props => [
    id,
    postId,
    authorId,
    authorName,
    parentCommentId,
    body,
    createdAt,
  ];
}
