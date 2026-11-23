import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/doulapp_logo.dart';
import '../../../../core/widgets/soft_orb.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: -120,
            top: -100,
            child: SoftOrb(
              size: 300,
              color: AppColors.sageLight.withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            right: -130,
            bottom: -110,
            child: SoftOrb(
              size: 320,
              color: AppColors.blush.withValues(alpha: 0.26),
            ),
          ),
          SafeArea(
            child: BlocConsumer<LoginBloc, LoginState>(
              listener: (context, state) {
                if (state is LoginSuccess) {
                  context.go(AppRoutes.postAuth);
                }
              },
              builder: (context, state) {
                final isLoading = state is LoginLoading;
                final errorMessage = state is LoginFailure
                    ? state.message
                    : null;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - AppSpacing.xxl * 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            const DoulappLogo(size: 78),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Bienvenida a Doulapp',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Un espacio para cuidarte, escucharte y pedir\napoyo cuando lo necesites.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            if (errorMessage != null) ...[
                              _ErrorBanner(message: errorMessage),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            AppCard(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Correo electrónico',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    key: const Key('login_email_field'),
                                    controller: _emailController,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    decoration: const InputDecoration(
                                      hintText: 'tucorreo@ejemplo.com',
                                      prefixIcon: Icon(
                                        Icons.mail_outline_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    'Contraseña',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    key: const Key('login_password_field'),
                                    controller: _passwordController,
                                    enabled: !isLoading,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) =>
                                        isLoading ? null : _submit(),
                                    decoration: InputDecoration(
                                      hintText: 'Tu contraseña',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      key: const Key('login_to_forgot_button'),
                                      onPressed: isLoading
                                          ? null
                                          : () => context.go(
                                              AppRoutes.forgotPassword,
                                            ),
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                      ),
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ElevatedButton(
                                    key: const Key('login_submit_button'),
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
                                        : const Text('Iniciar sesión'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextButton(
                              key: const Key('login_to_register_button'),
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppRoutes.register),
                              child: const Text(
                                '¿No tienes una cuenta? Crear cuenta',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de error del formulario, con el tono rosado de la paleta.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.blushContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
