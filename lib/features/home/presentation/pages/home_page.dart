import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/soft_orb.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';

/// Pantalla principal. Saluda por el nombre del perfil, que viene del mismo
/// [ProfileBloc] que usa la pestaña de perfil.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            right: -120,
            top: -90,
            child: SoftOrb(
              size: 260,
              color: AppColors.sageLight.withValues(alpha: 0.26),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BlocBuilder<ProfileBloc, ProfileState>(
                              builder: (context, state) => Text(
                                _greeting(state),
                                key: const Key('home_greeting'),
                                style: textTheme.headlineMedium,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '¿Cómo estás hoy?',
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundIconButton(
                        key: const Key('home_notifications_button'),
                        icon: Icons.notifications_none_rounded,
                        onTap: () => showComingSoon(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      _FeatureCard(onTap: () => showComingSoon(context)),
                      const SizedBox(height: 28),
                      Text(
                        '¿QUÉ NECESITAS HOY?',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MenuGrid(
                        cards: [
                          _MenuCardData(
                            key: 'for_me',
                            icon: Icons.spa_outlined,
                            title: 'Para mí',
                            subtitle: 'Un pequeño espacio para ti.',
                            onTap: () => context.go(AppRoutes.forMe),
                          ),
                          _MenuCardData(
                            key: 'support',
                            icon: Icons.favorite_border_rounded,
                            title: 'Red de apoyo',
                            subtitle: 'Pide ayuda cuando la necesites.',
                            onTap: () => context.go(AppRoutes.support),
                          ),
                          _MenuCardData(
                            key: 'learn',
                            icon: Icons.menu_book_outlined,
                            title: 'Aprende sobre ti',
                            subtitle: 'Información sobre emociones y posparto.',
                            soon: true,
                            onTap: () => showComingSoon(context),
                          ),
                          _MenuCardData(
                            key: 'stories',
                            icon: Icons.forum_outlined,
                            title: 'Historias reales',
                            subtitle: 'Experiencias de otras madres.',
                            soon: true,
                            onTap: () => showComingSoon(context),
                          ),
                          _MenuCardData(
                            key: 'wellbeing',
                            icon: Icons.sentiment_satisfied_outlined,
                            title: 'Mi bienestar',
                            subtitle: 'Conoce y registra cómo te sientes.',
                            onTap: () => context.push(AppRoutes.moodCheckin),
                          ),
                          _MenuCardData(
                            key: 'resources',
                            icon: Icons.place_outlined,
                            title: 'Recursos cerca de ti',
                            subtitle: 'Encuentra opciones de apoyo.',
                            soon: true,
                            onTap: () => showComingSoon(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// «Hola, Karla» con el primer nombre; «Hola» mientras el perfil carga.
  static String _greeting(ProfileState state) {
    if (state is ProfileLoaded) {
      final first = state.profile.displayName
          .trim()
          .split(RegExp(r'\s+'))
          .first;
      if (first.isNotEmpty) return 'Hola, $first';
    }
    return 'Hola';
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCCFFFFFF),
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FeatureCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home_feature_card'),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.sageMid,
                AppColors.sageDeep,
                Color(0xFF3F6547),
              ],
              stops: [0, 0.62, 1],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D4A7350),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.spa_outlined,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'UN MOMENTO PARA TI',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '¿Tienes unos minutos\npara ti?',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 232),
                child: Text(
                  'Una pausa breve, a tu ritmo. Sin prisa y sin culpa.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Comenzar',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sageDark,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.sageDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCardData {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool soon;
  final VoidCallback onTap;

  const _MenuCardData({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.soon = false,
  });
}

class _MenuGrid extends StatelessWidget {
  final List<_MenuCardData> cards;

  const _MenuGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _MenuCard(data: cards[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < cards.length
                    ? _MenuCard(data: cards[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < cards.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuCardData data;

  const _MenuCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('home_card_${data.key}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: data.onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 17),
          decoration: BoxDecoration(
            color: data.soon ? const Color(0x8CFFFFFF) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: data.soon ? const Color(0x2426382D) : AppColors.lineSoft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(data.icon, size: 22, color: AppColors.sage),
                  ),
                  if (data.soon)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.beige,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: const Text(
                          'Próximamente',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E978F),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.title,
                style: textTheme.titleMedium?.copyWith(fontSize: 14.5),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
