import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/app_role.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_avatar.dart';

export '../widgets/profile_avatar.dart' show initialsOf;

/// Resumen del perfil: quién es la usuaria, su privacidad y los ajustes de la
/// cuenta, con el cierre de sesión al final.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileSignedOut) {
              context.go(AppRoutes.login);
            }
          },
          builder: (context, state) {
            return switch (state) {
              ProfileInitial() || ProfileLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.sage),
              ),
              ProfileFailure(:final message) => _ProfileErrorView(
                message: message,
                onRetry: () => context.read<ProfileBloc>().add(
                  const ProfileLoadRequested(),
                ),
              ),
              ProfileLoaded(:final profile, :final email, :final role) =>
                _ProfileContentView(
                  profile: profile,
                  email: email,
                  role: role,
                  onSignOut: () => context.read<ProfileBloc>().add(
                    const ProfileSignOutRequested(),
                  ),
                ),
              ProfileSignedOut() => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}

class _ProfileContentView extends StatelessWidget {
  final Profile profile;
  final String email;
  final AppRole? role;
  final VoidCallback onSignOut;

  const _ProfileContentView({
    required this.profile,
    required this.email,
    required this.role,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text('Perfil', style: textTheme.headlineMedium),
        const SizedBox(height: 20),
        _Header(profile: profile, role: role),
        const SizedBox(height: 24),
        _PrivacyPanel(onAdjust: () => context.push(AppRoutes.privacy)),
        const SizedBox(height: 16),
        _SettingsList(
          rows: [
            _SettingsRow(
              key: 'info',
              icon: Icons.person_outline_rounded,
              title: 'Mi información',
              subtitle: 'Nombre, correo y datos de la cuenta',
              onTap: () => _showAccountInfo(
                context,
                profile: profile,
                email: email,
                role: role,
              ),
            ),
            _SettingsRow(
              key: 'network',
              icon: Icons.people_outline_rounded,
              title: 'Mi red de apoyo',
              subtitle: 'Las personas de tu confianza',
              onTap: () => showComingSoon(context),
            ),
            _SettingsRow(
              key: 'notifications',
              icon: Icons.notifications_none_rounded,
              title: 'Notificaciones',
              subtitle: 'Recordatorios suaves, nunca insistentes',
              onTap: () => context.push(AppRoutes.notifications),
            ),
            _SettingsRow(
              key: 'help',
              icon: Icons.help_outline_rounded,
              title: 'Ayuda',
              subtitle: 'Preguntas frecuentes y contacto',
              onTap: () => showComingSoon(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('profile_sign_out_button'),
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.sageDark,
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: AppColors.sageLight, width: 1.5),
            shape: const StadiumBorder(),
            textStyle: textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Doulapp · versión 1.0',
            style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Profile profile;
  final AppRole? role;

  const _Header({required this.profile, required this.role});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        ProfileAvatar(
          key: const Key('profile_avatar'),
          initials: initialsOf(profile.displayName),
          avatarUrl: profile.avatarUrl,
        ),
        const SizedBox(height: 14),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text('Tu espacio personal', style: textTheme.bodyMedium),
        if (role != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('profile_role_chip'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              role!.label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.sageDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrivacyPanel extends StatelessWidget {
  final VoidCallback onAdjust;

  const _PrivacyPanel({required this.onAdjust});

  static const _promises = [
    'Tu red solo ve lo que tú envías',
    'Tus microdescansos son solo tuyos',
    'Puedes salir de una solicitud cuando quieras',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF4F6F0)],
        ),
        border: Border.all(
          color: AppColors.sage.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sage.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.sage),
              const SizedBox(width: 10),
              Text('Privacidad', style: textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tú decides qué se comparte y con quién.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          for (final promise in _promises)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 19,
                    height: 19,
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      promise,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          TextButton(
            key: const Key('profile_privacy_button'),
            onPressed: onAdjust,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Ajustar mi privacidad',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _SettingsList extends StatelessWidget {
  final List<_SettingsRow> rows;

  const _SettingsList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.lineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            InkWell(
              key: Key('profile_row_${rows[i].key}'),
              onTap: rows[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(
                        rows[i].icon,
                        size: 21,
                        color: AppColors.sage,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[i].title,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rows[i].subtitle,
                            style: textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB4BBB5),
                    ),
                  ],
                ),
              ),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, color: AppColors.lineSoft),
          ],
        ],
      ),
    );
  }
}

String _statusLabel(AccountStatus status) => switch (status) {
  AccountStatus.active => 'Activa',
  AccountStatus.suspended => 'Suspendida',
  AccountStatus.deactivated => 'Desactivada',
};

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// «1 de febrero de 2026»
@visibleForTesting
String formatDate(DateTime date) =>
    '${date.day} de ${_months[date.month - 1]} de ${date.year}';

Future<void> _showAccountInfo(
  BuildContext context, {
  required Profile profile,
  required String email,
  required AppRole? role,
}) {
  final textTheme = Theme.of(context).textTheme;
  final bio = profile.bio?.trim();

  Widget row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(value, style: textTheme.bodyLarge),
      ],
    ),
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mi información', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            row('Nombre', profile.displayName),
            row('Correo', email),
            if (role != null) row('Rol', role.label),
            row('Estado de la cuenta', _statusLabel(profile.accountStatus)),
            row('Miembro desde', formatDate(profile.createdAt)),
            if (bio != null && bio.isNotEmpty) row('Sobre ti', bio),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('account_info_edit_button'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.editProfile);
              },
              child: const Text('Editar perfil'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('account_info_close_button'),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Perfil', style: textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.error),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Volver a intentar'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Ir a iniciar sesión'),
          ),
        ],
      ),
    );
  }
}
