import '../../domain/entities/post_comment.dart';

/// Una fila de `comments` con la autora embebida como `author`.
class PostCommentModel extends PostComment {
  const PostCommentModel({
    required super.id,
    required super.postId,
    required super.authorId,
    super.authorName,
    super.parentCommentId,
    required super.body,
    required super.createdAt,
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'];

    return PostCommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorName: author is Map<String, dynamic>
          ? author['display_name'] as String?
          : null,
      parentCommentId: json['parent_comment_id'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
