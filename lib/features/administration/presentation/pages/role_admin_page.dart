import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../moderation/presentation/widgets/report_widgets.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../../domain/entities/managed_user.dart';
import '../bloc/role_admin_bloc.dart';
import '../bloc/role_admin_event.dart';
import '../bloc/role_admin_state.dart';

String managedUserLabel(ManagedUser user) {
  final name = user.displayName?.trim();
  return name == null || name.isEmpty ? 'Usuaria de Doulapp' : name;
}

/// Perfil → Administración: buscar usuarias y gestionar el rol de moderadora.
class RoleAdminPage extends StatefulWidget {
  const RoleAdminPage({super.key});

  @override
  State<RoleAdminPage> createState() => _RoleAdminPageState();
}

class _RoleAdminPageState extends State<RoleAdminPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() => context.read<RoleAdminBloc>().add(
    RoleAdminSearchSubmitted(_controller.text),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administración')),
      body: SafeArea(
        child: BlocConsumer<RoleAdminBloc, RoleAdminState>(
          listenWhen: (previous, current) =>
              current.notice != null && current.noticeId != previous.noticeId,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.notice!)));
          },
          builder: (context, state) {
            if (state.status == RoleAdminStatus.forbidden) {
              return const _Message(
                icon: Icons.lock_outline_rounded,
                title: 'Esta sección es para administración',
                message: 'Tu cuenta no tiene permiso para gestionar roles.',
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    key: const Key('admin_search'),
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Buscar usuaria por nombre',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        key: const Key('admin_search_button'),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        tooltip: 'Buscar',
                        onPressed: _search,
                      ),
                    ),
                  ),
                ),
                if (state.status == RoleAdminStatus.loading)
                  const LinearProgressIndicator(
                    key: Key('admin_loading'),
                    color: AppColors.sage,
                  ),
                Expanded(child: _Body(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final RoleAdminState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (state.status == RoleAdminStatus.failure) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos cargar la lista',
        message: state.errorMessage ?? '',
        actionLabel: 'Reintentar',
        onAction: () =>
            context.read<RoleAdminBloc>().add(const RoleAdminRetried()),
      );
    }

    if (state.status == RoleAdminStatus.initial ||
        (state.status == RoleAdminStatus.loading && state.users.isEmpty)) {
      return const Center(
        key: Key('admin_initial_loading'),
        child: CircularProgressIndicator(color: AppColors.sage),
      );
    }

    if (state.users.isEmpty) {
      return state.query.isEmpty
          ? const _Message(
              icon: Icons.groups_outlined,
              title: 'Aún no hay moderadoras',
              message:
                  'Busca a una usuaria por su nombre para darle el rol de '
                  'moderadora.',
            )
          : const _Message(
              icon: Icons.search_off_rounded,
              title: 'No encontramos usuarias con ese nombre',
              message:
                  'Revisa cómo se escribe. Las cuentas con perfil privado no '
                  'aparecen en la búsqueda.',
            );
    }

    return ListView(
      key: const Key('admin_list'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            state.query.isEmpty ? 'Equipo de moderación' : 'Resultados',
            style: textTheme.labelLarge?.copyWith(color: AppColors.inkSoft),
          ),
        ),
        for (final user in state.users) ...[
          _UserTile(user: user, working: state.workingUserId == user.id),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final ManagedUser user;
  final bool working;

  const _UserTile({required this.user, required this.working});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = managedUserLabel(user);
    final role = user.primaryRole;

    return Container(
      key: Key('admin_user_${user.id}'),
      padding: EdgeInsets.fromLTRB(14, 12, 10, user.isAdmin ? 12 : 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.lineSoft),
      ),
      // El botón va debajo: con letra grande o pantallas angostas no compite
      // con el nombre por el ancho.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    ModerationPill(
                      key: Key('admin_role_${user.id}'),
                      label: role.label,
                      color: switch (role) {
                        AppRole.admin => AppColors.sageDark,
                        AppRole.moderator => AppColors.sageMid,
                        AppRole.user => AppColors.inkSoft,
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!user.isAdmin)
            Align(
              alignment: Alignment.centerRight,
              child: _Action(user: user, working: working),
            ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final ManagedUser user;
  final bool working;

  const _Action({required this.user, required this.working});

  @override
  Widget build(BuildContext context) {
    if (working) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          key: Key('admin_working'),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.sage,
          ),
        ),
      );
    }

    final makeModerator = !user.isModerator;
    return TextButton(
      key: Key('admin_toggle_${user.id}'),
      // El tema pide ancho mínimo infinito; en una fila hay que acotarlo.
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: makeModerator ? AppColors.sageDark : AppColors.error,
      ),
      onPressed: () => _confirm(context, makeModerator),
      child: Text(makeModerator ? 'Hacer moderadora' : 'Quitar rol'),
    );
  }

  Future<void> _confirm(BuildContext context, bool makeModerator) async {
    final bloc = context.read<RoleAdminBloc>();
    final name = managedUserLabel(user);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          makeModerator
              ? '¿Hacer moderadora a $name?'
              : '¿Quitar el rol de moderadora a $name?',
        ),
        content: Text(
          makeModerator
              ? 'Podrá revisar reportes y ocultar o eliminar contenido de la '
                    'comunidad.'
              : 'Dejará de poder revisar reportes y moderar contenido.',
        ),
        actions: [
          TextButton(
            key: const Key('admin_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('admin_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(makeModerator ? 'Hacer moderadora' : 'Quitar rol'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(
        RoleAdminModeratorToggled(user: user, makeModerator: makeModerator),
      );
    }
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
                key: const Key('admin_retry'),
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
