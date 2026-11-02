import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doulapp_logo.dart';
import '../../../../core/widgets/soft_orb.dart';

/// Entrada de la aplicación. Pasa sola a [nextRoute] y también al tocarla.
class SplashPage extends StatefulWidget {
  /// Pantalla a la que se continúa: el inicio si ya hay sesión, el login si no.
  final String nextRoute;
  final Duration duration;

  const SplashPage({
    super.key,
    required this.nextRoute,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _continue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted) return;
    context.go(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GestureDetector(
        key: const Key('splash_area'),
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: Stack(
          children: [
            Positioned(
              left: -110,
              top: -90,
              child: SoftOrb(
                size: 300,
                color: AppColors.sageLight.withValues(alpha: 0.34),
              ),
            ),
            Positioned(
              right: -140,
              bottom: -100,
              child: SoftOrb(
                size: 340,
                color: AppColors.sage.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              right: -50,
              top: 150,
              child: SoftOrb(
                size: 180,
                color: AppColors.beige.withValues(alpha: 0.9),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const DoulappLogo(),
                          const SizedBox(height: 22),
                          Text(
                            'doulapp',
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 38,
                              letterSpacing: -1,
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 2,
                            margin: const EdgeInsets.symmetric(vertical: 22),
                            decoration: BoxDecoration(
                              color: AppColors.sageLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            'Tu bienestar también importa.',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 19,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acompañamiento posparto, sin prejuicios.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 34),
                    child: _LoadingDots(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value - index * 0.18) % 1;
            final pulse = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sage.withValues(alpha: 0.3 + 0.5 * pulse),
              ),
            );
          }),
        );
      },
    );
  }
}
