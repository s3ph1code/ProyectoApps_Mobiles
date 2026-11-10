import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../bloc/preferences_bloc.dart';
import '../bloc/preferences_event.dart';
import '../bloc/preferences_state.dart';
import '../widgets/preferences_scaffold.dart';

/// Avisos y recordatorios. Cada interruptor se guarda al instante.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PreferencesScaffold(
      title: 'Notificaciones',
      builder: (context, PreferencesLoaded state) {
        final textTheme = Theme.of(context).textTheme;
        final bloc = context.read<PreferencesBloc>();
        final prefs = state.preferences;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text(
              'Recordatorios suaves, nunca insistentes. Tú decides cuáles '
              'recibir.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                side: const BorderSide(color: AppColors.lineSoft),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('preferences_notifications_switch'),
                    title: const Text('Notificaciones'),
                    subtitle: const Text(
                      'Avisos de la comunidad, como comentarios y reacciones.',
                    ),
                    value: prefs.allowNotifications,
                    onChanged: state.isSaving
                        ? null
                        : (value) =>
                              bloc.add(PreferencesNotificationsChanged(value)),
                  ),
                  const Divider(height: 1, color: AppColors.lineSoft),
                  SwitchListTile(
                    key: const Key('preferences_reminders_switch'),
                    title: const Text('Recordatorios de bienestar'),
                    subtitle: const Text(
                      'Una invitación amable a tomarte un momento para ti.',
                    ),
                    value: prefs.wellbeingReminders,
                    onChanged: state.isSaving
                        ? null
                        : (value) =>
                              bloc.add(PreferencesRemindersChanged(value)),
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
