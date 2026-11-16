import 'package:doulapp/features/community/domain/entities/community_category.dart';
import 'package:doulapp/features/community/domain/entities/post.dart';
import 'package:doulapp/features/community/domain/entities/post_comment.dart';
import 'package:doulapp/features/community/domain/entities/post_type.dart';
import 'package:doulapp/features/community/domain/entities/post_visibility.dart';

const emotions = CommunityCategory(
  id: 'cat-1',
  name: 'Emociones',
  slug: 'emociones',
);
const sleep = CommunityCategory(
  id: 'cat-2',
  name: 'Sueño y cansancio',
  slug: 'sueno-y-cansancio',
);
const testCategories = [emotions, sleep];

Post makePost(
  String id, {
  String? authorName = 'Ana',
  String body = 'De noche todo se siente más pesado.',
  PostType type = PostType.question,
  List<CommunityCategory> categories = const [emotions],
  int reactions = 3,
  int comments = 2,
  DateTime? createdAt,
}) {
  return Post(
    id: id,
    authorId: 'author-$id',
    authorName: authorName,
    type: type,
    body: body,
    visibility: PostVisibility.community,
    createdAt: createdAt ?? DateTime.utc(2026, 11, 10, 15),
    categories: categories,
    reactionCount: reactions,
    commentCount: comments,
  );
}

/// [count] publicaciones con ids `p<start>`, `p<start+1>`…
List<Post> makePosts(int count, {int start = 0}) => [
  for (var i = start; i < start + count; i++) makePost('p$i'),
];

PostComment makeComment(
  String id, {
  String? parent,
  int minute = 0,
  String? authorName = 'Bea',
}) {
  return PostComment(
    id: id,
    postId: 'p0',
    authorId: 'author-$id',
    authorName: authorName,
    parentCommentId: parent,
    body: 'Comentario $id',
    createdAt: DateTime.utc(2026, 11, 10, 16, minute),
  );
}
