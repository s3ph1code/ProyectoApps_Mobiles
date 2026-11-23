import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/blocked_user.dart';
import '../bloc/blocked_users_bloc.dart';
import '../bloc/blocked_users_event.dart';
import '../bloc/blocked_users_state.dart';

String blockedUserLabel(BlockedUser user) {
  final name = user.displayName?.trim();
  return name == null || name.isEmpty ? 'Usuaria de Doulapp' : name;
}

/// Las usuarias que bloqueé, con un «Desbloquear» en cada fila.
class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarias bloqueadas')),
      body: SafeArea(
        child: BlocConsumer<BlockedUsersBloc, BlockedUsersState>(
          listenWhen: (previous, current) =>
              current is BlockedUsersLoaded &&
              (current.justUnblocked != null || current.errorMessage != null) &&
              previous != current,
          listener: _showNotice,
          builder: (context, state) => switch (state) {
            BlockedUsersInitial() || BlockedUsersLoading() => const Center(
              key: Key('blocked_loading'),
              child: CircularProgressIndicator(color: AppColors.sage),
            ),
            BlockedUsersFailure(:final message) => _Message(
              icon: Icons.cloud_off_rounded,
              title: 'No pudimos cargar la lista',
              message: message,
              actionLabel: 'Reintentar',
              onAction: () => context.read<BlockedUsersBloc>().add(
                const BlockedUsersRequested(),
              ),
            ),
            BlockedUsersLoaded(:final users) when users.isEmpty =>
              const _Message(
                icon: Icons.favorite_border_rounded,
                title: 'No has bloqueado a nadie',
                message:
                    'Si alguna vez una publicación o un comentario te '
                    'incomoda, puedes bloquear a su autora desde el menú «⋯». '
                    'Aquí podrás verlas y desbloquearlas.',
              ),
            BlockedUsersLoaded(:final users) => ListView.separated(
              key: const Key('blocked_list'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _BlockedTile(user: users[index]),
            ),
          },
        ),
      ),
    );
  }

  void _showNotice(BuildContext context, BlockedUsersState state) {
    final loaded = state as BlockedUsersLoaded;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final unblocked = loaded.justUnblocked;

    if (unblocked != null) {
      final bloc = context.read<BlockedUsersBloc>();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Desbloqueaste a ${blockedUserLabel(unblocked)}'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => bloc.add(BlockedUserRestored(unblocked)),
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(loaded.errorMessage!)));
  }
}

class _BlockedTile extends StatelessWidget {
  final BlockedUser user;

  const _BlockedTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = blockedUserLabel(user);

    return Container(
      key: Key('blocked_${user.userId}'),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.sage.withValues(alpha: 0.15),
            child: Text(
              label.characters.first.toUpperCase(),
              style: textTheme.titleMedium?.copyWith(color: AppColors.sage),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall,
            ),
          ),
          TextButton(
            key: Key('unblock_${user.userId}'),
            onPressed: () => context.read<BlockedUsersBloc>().add(
              BlockedUserUnblocked(user),
            ),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.sage),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('blocked_retry'),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
