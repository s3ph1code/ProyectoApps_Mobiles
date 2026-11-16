import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/soft_orb.dart';
import '../../domain/entities/activity.dart';
import '../bloc/activity_session_bloc.dart';
import '../bloc/activity_session_event.dart';
import '../bloc/activity_session_state.dart';

/// Pantalla para realizar una actividad con temporizador y marcarla como
/// completada o salir en cualquier momento sin mensajes de culpa.
class ActivitySessionPage extends StatelessWidget {
  final Activity activity;

  const ActivitySessionPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivitySessionBloc, ActivitySessionState>(
      listener: (context, state) {
        if (state is ActivitySessionAbandonedState) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.activities);
          }
        }
      },
      builder: (context, state) => switch (state) {
        ActivitySessionInitial() ||
        ActivitySessionStarting() =>
          const _LoadingSessionView(),
        ActivitySessionActive() => _ActiveSessionView(state: state),
        ActivitySessionCompleted() => _CompletedSessionView(state: state),
        ActivitySessionAbandonedState() => const SizedBox.shrink(),
      },
    );
  }
}

class _LoadingSessionView extends StatelessWidget {
  const _LoadingSessionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(key: Key('activity_session_loading')),
      ),
    );
  }
}

class _ActiveSessionView extends StatelessWidget {
  final ActivitySessionActive state;

  const _ActiveSessionView({required this.state});

  static String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _confirmExit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Quieres terminar tu pausa por ahora?',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Está bien si no tienes más tiempo hoy. Tu bienestar se cuida momento a momento, sin culpas.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('activity_session_confirm_exit_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.beige,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.read<ActivitySessionBloc>().add(
                    const ActivitySessionAbandoned(),
                  );
                },
                child: const Text('Salir por ahora'),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const Key('activity_session_continue_button'),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Continuar mi pausa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activity = state.activity;
    final content = activity.contentText ?? activity.description;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            right: -80,
            top: -60,
            child: SoftOrb(
              size: 240,
              color: AppColors.sageLight.withValues(alpha: 0.22),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('activity_session_close_button'),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.ink,
                        onPressed: () => _confirmExit(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.sessionWarning != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.beige.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.inkSoft,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.sessionWarning!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.sage.withValues(alpha: 0.25),
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C26382D),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(state.elapsedSeconds),
                                key: const Key('activity_session_timer_text'),
                                style: textTheme.headlineMedium?.copyWith(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sageDark,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A tu propio ritmo',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(color: AppColors.lineSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.spa_outlined,
                                  size: 18,
                                  color: AppColors.sage,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Guía de la actividad',
                                    style: textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.sageDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              content,
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: ElevatedButton(
                    key: const Key('activity_session_finish_button'),
                    onPressed: () {
                      context.read<ActivitySessionBloc>().add(
                        const ActivitySessionFinished(),
                      );
                    },
                    child: const Text('Finalizar pausa'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedSessionView extends StatelessWidget {
  final ActivitySessionCompleted state;

  const _CompletedSessionView({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final minutes = (state.elapsedSeconds ~/ 60);
    final seconds = (state.elapsedSeconds % 60);

    final timeDescription = minutes > 0
        ? '$minutes min y $seconds seg'
        : '$seconds segundos';

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            right: -60,
            top: -50,
            child: SoftOrb(
              size: 260,
              color: AppColors.sageLight.withValues(alpha: 0.28),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: AppColors.beige,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 46,
                        color: AppColors.sageDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Pausa completada!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Te regalaste $timeDescription para ti. Cada pequeño momento cuenta y tu bienestar importa.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    key: const Key('activity_session_checkin_button'),
                    onPressed: () => context.push(AppRoutes.moodCheckin),
                    child: const Text('Hacer un check-in de ánimo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('activity_session_return_button'),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.activities);
                      }
                    },
                    child: const Text('Volver a microdescansos'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
