import 'package:equatable/equatable.dart';

import 'community_category.dart';
import 'post_type.dart';
import 'post_visibility.dart';

/// Una publicación de la comunidad, con lo que el feed necesita mostrar.
class Post extends Equatable {
  final String id;
  final String authorId;

  /// `null` cuando la autora tiene el perfil privado o ya no existe.
  final String? authorName;
  final String? authorAvatarUrl;
  final PostType type;
  final String body;
  final PostVisibility visibility;
  final DateTime createdAt;
  final List<CommunityCategory> categories;
  final int reactionCount;
  final int commentCount;

  const Post({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.type,
    required this.body,
    required this.visibility,
    required this.createdAt,
    this.categories = const [],
    this.reactionCount = 0,
    this.commentCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    authorId,
    authorName,
    authorAvatarUrl,
    type,
    body,
    visibility,
    createdAt,
    categories,
    reactionCount,
    commentCount,
  ];
}
