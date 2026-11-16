import '../../domain/entities/post.dart';
import '../../domain/entities/post_type.dart';
import '../../domain/entities/post_visibility.dart';
import 'community_category_model.dart';

/// Una fila de la vista `post_feed`.
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.authorId,
    super.authorName,
    super.authorAvatarUrl,
    required super.type,
    required super.body,
    required super.visibility,
    required super.createdAt,
    super.categories,
    super.reactionCount,
    super.commentCount,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];

    return PostModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      type: PostType.fromCode(json['post_type'] as String),
      body: json['body'] as String,
      visibility: PostVisibility.fromCode(json['visibility'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      categories: categories is List
          ? categories
                .whereType<Map<String, dynamic>>()
                .map(CommunityCategoryModel.fromJson)
                .toList()
          : const [],
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    );
  }
}
