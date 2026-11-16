import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community_category.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/community_message_view.dart';
import '../widgets/post_card.dart';

/// «Comunidad»: lo que comparten otras madres, filtrable por categoría.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  Future<void> _openComposer(BuildContext context) async {
    final bloc = context.read<FeedBloc>();
    final published = await context.push<bool>(AppRoutes.createPost);
    // Vuelve a «Todas» para que la publicación nueva quede arriba aunque no
    // sea de la categoría que estaba filtrada.
    if (published == true) bloc.add(const FeedCategorySelected(null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('feed_write_button'),
        onPressed: () => _openComposer(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Escribir'),
      ),
      body: SafeArea(
        child: BlocBuilder<FeedBloc, FeedState>(
          builder: (context, state) => switch (state) {
            FeedInitial() || FeedLoading() => const Center(
              key: Key('feed_loading'),
              child: CircularProgressIndicator(),
            ),
            FeedFailure(:final message) => CommunityMessageView(
              icon: Icons.cloud_off_rounded,
              title: 'No pudimos cargar la comunidad',
              message: message,
              actionLabel: 'Reintentar',
              actionKey: const Key('feed_retry_button'),
              onAction: () =>
                  context.read<FeedBloc>().add(const FeedRequested()),
            ),
            FeedLoaded() => _FeedView(state: state),
          },
        ),
      ),
    );
  }
}

class _FeedView extends StatelessWidget {
  final FeedLoaded state;

  const _FeedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FeedBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryFilters(
          categories: state.categories,
          selectedCategoryId: state.selectedCategoryId,
        ),
        if (state.isReloading)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const FeedRefreshed());
              await bloc.stream.firstWhere(
                (s) => s is! FeedLoaded || !s.isReloading,
              );
            },
            child: state.isEmpty
                ? _EmptyFeed(filtered: state.selectedCategoryId != null)
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 400) {
                        bloc.add(const FeedNextPageRequested());
                      }
                      return false;
                    },
                    child: ListView.separated(
                      key: const Key('feed_list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Espacio abajo para que el botón «Escribir» no tape la
                      // última publicación.
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      itemCount: state.posts.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == state.posts.length) {
                          return _ListFooter(state: state);
                        }
                        final post = state.posts[index];
                        return PostCard(
                          key: Key('feed_post_${post.id}'),
                          post: post,
                          onTap: () =>
                              context.push(AppRoutes.postDetailPath(post.id)),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Chips de categoría con «Todas» al principio, desplazables en horizontal.
class _CategoryFilters extends StatelessWidget {
  final List<CommunityCategory> categories;
  final String? selectedCategoryId;

  const _CategoryFilters({
    required this.categories,
    required this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FeedBloc>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _FilterChip(
            key: const Key('feed_filter_all'),
            label: 'Todas',
            selected: selectedCategoryId == null,
            onSelected: () => bloc.add(const FeedCategorySelected(null)),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _FilterChip(
              key: Key('feed_filter_${category.id}'),
              label: category.name,
              selected: selectedCategoryId == category.id,
              onSelected: () => bloc.add(FeedCategorySelected(category.id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) {
        if (!selected) onSelected();
      },
      selectedColor: AppColors.sage.withValues(alpha: 0.18),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? AppColors.sageDark : AppColors.inkSoft,
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final FeedLoaded state;

  const _ListFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        key: Key('feed_loading_more'),
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = state.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
            ),
            TextButton(
              key: const Key('feed_load_more_retry'),
              onPressed: () =>
                  context.read<FeedBloc>().add(const FeedNextPageRequested()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _EmptyFeed extends StatelessWidget {
  final bool filtered;

  const _EmptyFeed({required this.filtered});

  @override
  Widget build(BuildContext context) {
    // Desplazable para que el gesto de actualizar funcione con la lista vacía.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: CommunityMessageView(
            key: const Key('feed_empty'),
            icon: Icons.forum_outlined,
            title: filtered
                ? 'Aún no hay publicaciones en esta categoría'
                : 'Aún no hay publicaciones',
            message: filtered
                ? 'Prueba con otra categoría o escribe la primera.'
                : 'Puedes ser la primera en compartir algo con la comunidad.',
            actionLabel: filtered ? 'Ver todas' : null,
            actionKey: const Key('feed_empty_show_all'),
            onAction: filtered
                ? () => context.read<FeedBloc>().add(
                    const FeedCategorySelected(null),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
