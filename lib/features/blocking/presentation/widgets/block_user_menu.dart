import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/block_user_bloc.dart';
import '../bloc/block_user_event.dart';
import '../bloc/block_user_state.dart';

/// El «⋯» de una publicación o comentario ajeno. Abre una hoja inferior con
/// «Bloquear a esta usuaria»; pide confirmación con una explicación tranquila
/// y, al bloquear, avisa con un «Deshacer».
class BlockUserMenu extends StatelessWidget {
  final String authorId;

  /// `null` cuando su perfil es privado.
  final String? authorName;

  const BlockUserMenu({super.key, required this.authorId, this.authorName});

  String get _who {
    final name = authorName?.trim();
    return name == null || name.isEmpty ? 'esta usuaria' : name;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key('block_menu_$authorId'),
      tooltip: 'Más opciones',
      icon: const Icon(Icons.more_horiz_rounded),
      color: AppColors.inkSoft,
      visualDensity: VisualDensity.compact,
      onPressed: () => _openSheet(context),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          key: const Key('block_menu_option'),
          leading: const Icon(Icons.block_rounded),
          title: Text('Bloquear a $_who'),
          onTap: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
    );
    if (choice != true || !context.mounted) return;
    await _confirmAndBlock(context);
  }

  Future<void> _confirmAndBlock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Bloquear a $_who?'),
        content: const Text(
          'No se enterará de que la bloqueaste. Dejarás de ver sus '
          'publicaciones y comentarios. Puedes desbloquearla cuando quieras '
          'desde Perfil → Privacidad.',
        ),
        actions: [
          TextButton(
            key: const Key('block_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('block_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final bloc = context.read<BlockUserBloc>();
    final messenger = ScaffoldMessenger.of(context);
    bloc.add(
      BlockUserRequested(blockedUserId: authorId, blockedUserName: authorName),
    );

    final result = await bloc.stream.firstWhere(
      (s) => s is BlockUserBlocked || s is BlockUserFailure,
    );
    messenger.hideCurrentSnackBar();

    if (result is BlockUserFailure) {
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Bloqueaste a $_who'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => bloc.add(UnblockUserRequested(authorId)),
        ),
      ),
    );
  }
}
