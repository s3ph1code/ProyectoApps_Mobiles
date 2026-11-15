import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/soft_orb.dart';

/// Pestaña «Para mí». Espacio central de autocuidado, pausas breves,
/// microdescansos y bienestar emocional.
class ForMePage extends StatelessWidget {
  const ForMePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            right: -100,
            top: -80,
            child: SoftOrb(
              size: 240,
              color: AppColors.sageLight.withValues(alpha: 0.22),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                Text(
                  'Para mí',
                  key: const Key('for_me_title'),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Un espacio a tu ritmo. Tómate el tiempo que necesites, sin exigencias.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 24),
                _ForMeCard(
                  key: const Key('for_me_card_activities'),
                  icon: Icons.spa_outlined,
                  title: 'Microdescansos',
                  subtitle:
                      'Pausas breves de respiración, descanso y movimiento suave.',
                  onTap: () => context.push(AppRoutes.activities),
                ),
                const SizedBox(height: 14),
                _ForMeCard(
                  key: const Key('for_me_card_saved'),
                  icon: Icons.bookmark_border_rounded,
                  title: 'Actividades guardadas',
                  subtitle:
                      'Tus pausas favoritas a mano para cuando las necesites.',
                  onTap: () => context.push(AppRoutes.savedActivities),
                ),
                const SizedBox(height: 14),
                _ForMeCard(
                  key: const Key('for_me_card_needs'),
                  icon: Icons.lightbulb_outline_rounded,
                  title: '«No sé qué necesito»',
                  subtitle:
                      'Elige lo que estás sintiendo y recibe sugerencias con cariño.',
                  onTap: () => context.push(AppRoutes.needs),
                ),
                const SizedBox(height: 14),
                _ForMeCard(
                  key: const Key('for_me_card_checkin'),
                  icon: Icons.sentiment_satisfied_outlined,
                  title: 'Check-in de bienestar',
                  subtitle: 'Registra cómo te sientes hoy, a tu propio ritmo.',
                  onTap: () => context.push(AppRoutes.moodCheckin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForMeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ForMeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.lineSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0826382D),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, size: 24, color: AppColors.sage),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
