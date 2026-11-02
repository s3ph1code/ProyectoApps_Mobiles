import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

const comingSoonTitle = 'Estamos preparando esto';
const comingSoonMessage =
    'Esta sección estará disponible en una próxima versión de Doulapp.';

/// Aviso breve para las secciones que aún no existen: no navega a ninguna
/// parte y se cierra con «Entendido».
Future<void> showComingSoon(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (sheetContext) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _ComingSoonContent(),
      ),
    ),
  );
}

class _ComingSoonContent extends StatelessWidget {
  const _ComingSoonContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.beige,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.spa_outlined,
            size: 30,
            color: AppColors.sageDark,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          comingSoonTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          comingSoonMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          key: const Key('coming_soon_ok_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

/// Pantalla completa para una pestaña cuyo módulo todavía no está disponible.
class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: textTheme.headlineMedium),
              const Spacer(),
              const _ComingSoonContent(),
              const Spacer(),
              TextButton(
                key: const Key('coming_soon_home_button'),
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
