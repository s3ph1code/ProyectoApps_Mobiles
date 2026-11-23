import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/post.dart';
import '../utils/community_format.dart';

/// Tarjeta de una publicación. En el feed muestra un extracto y abre el
/// detalle; en el detalle ([expanded]) muestra el texto completo.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final bool expanded;

  /// Menú «⋯» de la esquina (por ejemplo, bloquear a la autora). Opcional.
  final Widget? menu;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.expanded = false,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _AuthorAvatar(name: post.authorName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorLabel(post.authorName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    formatPostDate(post.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            _Pill(label: post.type.label, strong: true),
            if (menu != null) menu!,
          ],
        ),
        const SizedBox(height: 12),
        Text(
          post.body,
          maxLines: expanded ? null : 4,
          overflow: expanded ? null : TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        if (post.categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in post.categories)
                _Pill(label: category.name),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            _Counter(
              key: Key('post_reactions_${post.id}'),
              icon: Icons.favorite_border_rounded,
              count: post.reactionCount,
              label: post.reactionCount == 1 ? 'reacción' : 'reacciones',
            ),
            const SizedBox(width: 16),
            _Counter(
              key: Key('post_comments_${post.id}'),
              icon: Icons.chat_bubble_outline_rounded,
              count: post.commentCount,
              label: post.commentCount == 1 ? 'comentario' : 'comentarios',
            ),
          ],
        ),
      ],
    );

    final decoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: AppColors.lineSoft),
    );

    if (onTap == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: decoration,
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? name;

  const _AuthorAvatar({this.name});

  @override
  Widget build(BuildContext context) {
    final label = authorLabel(name);
    final initial = name == null || name!.trim().isEmpty
        ? null
        : label.characters.first.toUpperCase();

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.sage.withValues(alpha: 0.14),
      child: initial == null
          ? const Icon(Icons.person_outline, size: 20, color: AppColors.sage)
          : Text(
              initial,
              style: const TextStyle(
                color: AppColors.sageDark,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool strong;

  const _Pill({required this.label, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: strong
            ? AppColors.sage.withValues(alpha: 0.12)
            : AppColors.beige.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: strong ? AppColors.sageDark : AppColors.inkSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _Counter({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
