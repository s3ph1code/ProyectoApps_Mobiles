import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/soft_orb.dart';

/// Tres pasos que presentan el propósito de Doulapp. Los datos iniciales ya se
/// tomaron en el registro, así que aquí no se pide nada.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slides = [
    _Slide(
      icon: Icons.favorite_border_rounded,
      title: 'Aquí también\nestás tú.',
      body: 'Un espacio para acompañarte durante una etapa llena de cambios.',
    ),
    _Slide(
      icon: Icons.spa_outlined,
      title: 'Pequeños momentos\ntambién cuentan.',
      body: 'Encuentra espacios breves para reconectar contigo.',
    ),
    _Slide(
      icon: Icons.people_outline_rounded,
      title: 'No tienes que pedir\nayuda sola.',
      body: 'Conecta con tu red de confianza cuando necesites apoyo.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.go(AppRoutes.postAuth);

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

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
              size: 280,
              color: AppColors.sageLight.withValues(alpha: 0.3),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 12, 0),
                    child: TextButton(
                      key: const Key('onboarding_skip_button'),
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 40),
                        foregroundColor: AppColors.inkSoft,
                      ),
                      child: const Text('Saltar'),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    key: const Key('onboarding_pages'),
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Column(
                        children: [
                          Expanded(child: _Illustration(icon: slide.icon)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                            child: Column(
                              children: [
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: textTheme.displaySmall,
                                ),
                                const SizedBox(height: 12),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 290),
                                  child: Text(
                                    slide.body,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.inkSoft,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _Dots(count: _slides.length, index: _index),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  child: ElevatedButton(
                    key: const Key('onboarding_next_button'),
                    onPressed: _next,
                    child: Text(_isLast ? 'Comenzar' : 'Continuar'),
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

class _Slide {
  final IconData icon;
  final String title;
  final String body;

  const _Slide({required this.icon, required this.title, required this.body});
}

/// Ilustración orgánica: círculos concéntricos con un símbolo al centro.
class _Illustration extends StatelessWidget {
  final IconData icon;

  const _Illustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final outer = constraints.biggest.shortestSide.clamp(120.0, 260.0);
        return Center(
          child: SizedBox(
            width: outer,
            height: outer,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _circle(outer, AppColors.beige),
                _circle(outer * 0.74, AppColors.sageLight.withValues(alpha: 0.3)),
                _circle(outer * 0.5, AppColors.sage.withValues(alpha: 0.18)),
                Icon(icon, size: outer * 0.24, color: AppColors.sageDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;

  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('onboarding_dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: selected ? 26 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: selected ? AppColors.sage : const Color(0x2926382D),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
