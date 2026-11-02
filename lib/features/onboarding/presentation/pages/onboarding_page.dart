import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _displayNameController = TextEditingController();
  int _selectedSlide = 0;

  static const _slides = [
    _OnboardingSlideData(
      icon: Icons.favorite_outline,
      title: 'Aquí también estás tú.',
      subtitle:
          'Un espacio para acompañarte durante una etapa llena de cambios.',
    ),
    _OnboardingSlideData(
      icon: Icons.spa_outlined,
      title: 'Pequeños momentos también cuentan.',
      subtitle: 'Encuentra espacios breves para reconectar contigo.',
    ),
    _OnboardingSlideData(
      icon: Icons.people_outline,
      title: 'No tienes que pedir ayuda sola.',
      subtitle: 'Conecta con tu red de confianza cuando necesites apoyo.',
    ),
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<OnboardingBloc>().add(
          OnboardingSubmitted(displayName: _displayNameController.text),
        );
  }

  void _nextSlide() {
    setState(() {
      _selectedSlide = (_selectedSlide + 1) % _slides.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentSlide = _slides[_selectedSlide];

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is OnboardingSuccess) {
              context.go(AppRoutes.profile);
            } else if (state is OnboardingUnauthenticated) {
              context.go(AppRoutes.login);
            }
          },
          builder: (context, state) {
            final isLoading = state is OnboardingLoading;
            final errorMessage =
                state is OnboardingFailure ? state.message : null;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            key: const Key('onboarding_slide_card'),
                            onTap: _nextSlide,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.beige,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.sageLight.withValues(
                                          alpha: 0.45,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        currentSlide.icon,
                                        size: 28,
                                        color: AppColors.sageDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    currentSlide.title,
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    currentSlide.subtitle,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _slides.length,
                                      (index) {
                                        final isSelected =
                                            index == _selectedSlide;
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          width: isSelected ? 22 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.sage
                                                : AppColors.beige,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.xs,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 16),
                          Text(
                            '¿Cómo quieres que te llamemos?',
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Puedes usar tu nombre o un apodo con el que te sientas cómoda.',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          if (errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Text(
                                errorMessage,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'Nombre',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('onboarding_name_field'),
                            controller: _displayNameController,
                            enabled: !isLoading,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => isLoading ? null : _submit(),
                            decoration: const InputDecoration(
                              hintText: 'Tu nombre',
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            key: const Key('onboarding_submit_button'),
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Comenzar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
