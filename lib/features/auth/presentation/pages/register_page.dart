import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword.isNotEmpty && password != confirmPassword) {
      setState(() {
        _localError =
            'Las contraseñas no coinciden. Revisa que ambas sean iguales.';
      });
      return;
    }

    setState(() => _localError = null);

    context.read<RegisterBloc>().add(
          RegisterSubmitted(
            email: _emailController.text,
            password: password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterSuccess) {
              context.go(AppRoutes.onboarding);
            }
          },
          builder: (context, state) {
            final isLoading = state is RegisterLoading;
            final blocError = state is RegisterFailure ? state.message : null;
            final errorMessage = _localError ?? blocError;

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
                          Text(
                            'Crear tu cuenta',
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Solo lo esencial. Puedes completar el resto después.',
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
                            key: const Key('register_email_field'),
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
                          Text(
                            'Contraseña',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('register_password_field'),
                            controller: _passwordController,
                            enabled: !isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Mínimo 8 caracteres',
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
                          const SizedBox(height: 16),
                          Text(
                            'Confirmar contraseña',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('register_confirm_password_field'),
                            controller: _confirmPasswordController,
                            enabled: !isLoading,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => isLoading ? null : _submit(),
                            decoration: InputDecoration(
                              hintText: 'Repite tu contraseña',
                              suffixIcon: IconButton(
                                onPressed: isLoading
                                    ? null
                                    : () => setState(
                                          () => _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        ),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            key: const Key('register_submit_button'),
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
                                : const Text('Crear mi cuenta'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            key: const Key('register_to_login_button'),
                            onPressed: isLoading
                                ? null
                                : () => context.go(AppRoutes.login),
                            child: const Text(
                              '¿Ya tienes una cuenta? Iniciar sesión',
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
