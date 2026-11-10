import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/profile_visibility.dart';
import '../bloc/preferences_bloc.dart';
import '../bloc/preferences_event.dart';
import '../bloc/preferences_state.dart';
import '../widgets/preferences_scaffold.dart';

/// Quién ve mi perfil y cómo se usan mis datos. La visibilidad se guarda al
/// instante; el texto de uso de datos es estático.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const _options = [
    (
      visibility: ProfileVisibility.public,
      title: 'Pública',
      description:
          'Cualquier persona puede ver tu nombre y lo que cuentas '
          'sobre ti.',
    ),
    (
      visibility: ProfileVisibility.community,
      title: 'Comunidad',
      description: 'Las usuarias de Doulapp pueden ver tu perfil.',
    ),
    (
      visibility: ProfileVisibility.private,
      title: 'Solo yo',
      description: 'Nadie más puede ver tu perfil.',
    ),
  ];

  static const _dataUse = [
    'Guardamos tu nombre, tu correo y lo que decides compartir para que la '
        'app funcione.',
    'Tus registros de ánimo y tus microdescansos son solo tuyos: otras '
        'usuarias no los ven.',
    'Puedes cambiar estas opciones cuando quieras desde aquí.',
  ];

  @override
  Widget build(BuildContext context) {
    return PreferencesScaffold(
      title: 'Privacidad',
      builder: (context, PreferencesLoaded state) {
        final textTheme = Theme.of(context).textTheme;
        final bloc = context.read<PreferencesBloc>();
        final selected = state.preferences.profileVisibility;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text('¿Quién puede ver mi perfil?', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final option in _options) ...[
              _VisibilityTile(
                key: Key('privacy_option_${option.visibility.code}'),
                title: option.title,
                description: option.description,
                selected: option.visibility == selected,
                onTap: state.isSaving
                    ? null
                    : () => bloc.add(
                        PreferencesVisibilityChanged(option.visibility),
                      ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            Text('Cómo usamos tus datos', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              key: const Key('privacy_data_use'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.lineSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in _dataUse)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppColors.sage,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(line, style: textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  const _VisibilityTile({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.sage.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? AppColors.sage : AppColors.lineSoft,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(description, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.sage : AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
