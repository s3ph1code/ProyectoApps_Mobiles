import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

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
                  onRetry: () => context
                      .read<ProfileBloc>()
                      .add(const ProfileLoadRequested()),
                ),
              ProfileLoaded(:final profile, :final email) => _ProfileContentView(
                  profile: profile,
                  email: email,
                  onSignOut: () => context
                      .read<ProfileBloc>()
                      .add(const ProfileSignOutRequested()),
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
  final VoidCallback onSignOut;

  const _ProfileContentView({
    required this.profile,
    required this.email,
    required this.onSignOut,
  });

  String get _initial {
    final trimmed = profile.displayName.trim();
    if (trimmed.isEmpty) return 'D';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bio = profile.bio?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tu espacio', style: textTheme.displaySmall),
                  const SizedBox(height: 6),
                  Text(
                    'Tu bienestar también importa.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.beige,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _initial,
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: AppColors.sageDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.displayName,
                                      style: textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (bio != null && bio.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              bio,
                              style: textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'En tu acompañamiento',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const _UpcomingFeatureTile(
                    icon: Icons.spa_outlined,
                    title: 'Microdescansos',
                    subtitle: 'Pausas breves pensadas para ti',
                  ),
                  const SizedBox(height: 10),
                  const _UpcomingFeatureTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Bienestar emocional',
                    subtitle: 'Un espacio sin juicios para cómo te sientes',
                  ),
                  const SizedBox(height: 10),
                  const _UpcomingFeatureTile(
                    icon: Icons.people_outline_rounded,
                    title: 'Comunidad de madres',
                    subtitle: 'Experiencias y apoyo entre madres',
                  ),
                  const SizedBox(height: 10),
                  const _UpcomingFeatureTile(
                    icon: Icons.tune_rounded,
                    title: 'Preferencias y privacidad',
                    subtitle: 'Visibilidad del perfil y avisos',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onSignOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.sageDark,
              minimumSize: const Size.fromHeight(AppTheme.touchTargetHeight),
              side: const BorderSide(color: AppColors.sageLight, width: 1.5),
              shape: const StadiumBorder(),
              textStyle: textTheme.labelLarge,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _UpcomingFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _UpcomingFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTheme.touchTargetHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.beige),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.sage, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text(
                  'Próximamente',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sageDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tu espacio', style: textTheme.displaySmall),
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
