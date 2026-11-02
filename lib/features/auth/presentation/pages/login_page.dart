import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
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
      body: SafeArea(
        child: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              context.go(AppRoutes.postAuth);
            }
          },
          builder: (context, state) {
            final isLoading = state is LoginLoading;
            final errorMessage = state is LoginFailure ? state.message : null;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.beige,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.spa_outlined,
                                  color: AppColors.sageDark,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'doulapp',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AppColors.sageDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Bienvenida a Doulapp',
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Un espacio para cuidarte, escucharte y pedir apoyo cuando lo necesites.',
                            style: textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
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
                            'Correo electrónico',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('login_email_field'),
                            controller: _emailController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              hintText: 'tucorreo@ejemplo.com',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Contraseña', style: textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('login_password_field'),
                            controller: _passwordController,
                            enabled: !isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => isLoading ? null : _submit(),
                            decoration: InputDecoration(
                              hintText: 'Tu contraseña',
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
                                  : () => context.go(AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 10),
                          TextButton(
                            key: const Key('login_to_register_button'),
                            onPressed: isLoading
                                ? null
                                : () => context.go(AppRoutes.register),
                            child: const Text(
                              '¿No tienes una cuenta? Crear cuenta',
                            ),
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
