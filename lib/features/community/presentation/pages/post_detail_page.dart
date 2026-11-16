import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/post_comment.dart';
import '../bloc/post_detail_bloc.dart';
import '../bloc/post_detail_event.dart';
import '../bloc/post_detail_state.dart';
import '../utils/community_format.dart';
import '../widgets/community_message_view.dart';
import '../widgets/post_card.dart';

/// Una publicación completa con sus comentarios.
class PostDetailPage extends StatelessWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicación')),
      body: SafeArea(
        child: BlocBuilder<PostDetailBloc, PostDetailState>(
          builder: (context, state) => switch (state) {
            PostDetailLoading() => const Center(
              key: Key('post_detail_loading'),
              child: CircularProgressIndicator(),
            ),
            PostDetailFailure(:final message) => CommunityMessageView(
              icon: Icons.cloud_off_rounded,
              title: 'No pudimos abrir la publicación',
              message: message,
              actionLabel: 'Reintentar',
              actionKey: const Key('post_detail_retry'),
              onAction: () => context.read<PostDetailBloc>().add(
                PostDetailRequested(postId),
              ),
            ),
            PostDetailLoaded(:final post, :final comments) => ListView(
              key: const Key('post_detail_list'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                PostCard(post: post, expanded: true),
                const SizedBox(height: 24),
                Text(
                  comments.isEmpty
                      ? 'Comentarios'
                      : 'Comentarios (${comments.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (comments.isEmpty)
                  Text(
                    'Aún no hay comentarios.',
                    key: const Key('post_detail_no_comments'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  )
                else
                  for (final comment in comments) ...[
                    _CommentTile(comment: comment),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      key: Key('comment_${comment.id}'),
      padding: EdgeInsets.only(left: comment.isReply ? 28 : 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: comment.isReply
              ? AppColors.beige.withValues(alpha: 0.45)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    authorLabel(comment.authorName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatPostDate(comment.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(comment.body, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
