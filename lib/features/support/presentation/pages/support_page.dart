import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/soft_orb.dart';

/// Pestaña «Red de apoyo». Recursos de ayuda, orientación emocional
/// y la entrada a la comunidad.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            right: -90,
            top: -70,
            child: SoftOrb(
              size: 230,
              color: AppColors.sageLight.withValues(alpha: 0.20),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                Text(
                  'Red de apoyo',
                  key: const Key('support_title'),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Cuidar también es pedir ayuda. No tienes que hacerlo todo sola.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 24),
                _SupportCard(
                  key: const Key('support_card_helpline'),
                  icon: Icons.phone_in_talk_outlined,
                  title: 'Líneas de orientación y apoyo',
                  subtitle:
                      'Acompañamiento gratuito y confidencial en salud emocional.',
                  onTap: () => _showHelplineInfo(context),
                ),
                const SizedBox(height: 14),
                _SupportCard(
                  key: const Key('support_card_community'),
                  icon: Icons.forum_outlined,
                  title: 'Comunidad de madres',
                  subtitle:
                      'Un espacio seguro para compartir y escuchar experiencias.',
                  onTap: () => context.push(AppRoutes.community),
                ),
                const SizedBox(height: 14),
                _SupportCard(
                  key: const Key('support_card_network'),
                  icon: Icons.favorite_outline_rounded,
                  title: 'Tus personas de confianza',
                  subtitle:
                      'Ten a mano a familiares o amistades que puedan darte una mano hoy.',
                  onTap: () => _showNetworkTips(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showHelplineInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => SafeArea(
        // Desplazable: con este contenido la hoja no cabe en pantallas
        // cortas ni en horizontal, y el botón quedaba fuera de alcance.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Líneas de orientación y escucha',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Si sientes que necesitas hablar con alguien ahora mismo, recuerda que hay profesionales disponibles para escucharte sin juzgar.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.beige.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Línea 106 (Colombia) — Salud mental y apoyo emocional',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Atención gratuita y confidencial las 24 horas del día.',
                      style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('support_modal_ok_button'),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showNetworkTips(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => SafeArea(
        // Desplazable: con este contenido la hoja no cabe en pantallas
        // cortas ni en horizontal, y el botón quedaba fuera de alcance.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pedir ayuda es un acto de amor',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'A veces ayuda delegar una tarea puntual: que alguien te lleve un vaso de agua, sostenga al bebé unos minutos o te prepare algo caliente. No tienes que demostrar nada.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportCard({
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
                color: Color(0x14514599),
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
