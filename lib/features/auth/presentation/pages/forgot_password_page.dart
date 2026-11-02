import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_event.dart';
import '../bloc/forgot_password_state.dart';

/// Recuperar acceso: la usuaria escribe su correo y recibe un enlace para
/// elegir una contraseña nueva.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context
        .read<ForgotPasswordBloc>()
        .add(ForgotPasswordSubmitted(email: _emailController.text));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('forgot_back_button'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
          builder: (context, state) {
            final isLoading = state is ForgotPasswordLoading;
            final errorMessage =
                state is ForgotPasswordFailure ? state.message : null;
            final sentTo = state is ForgotPasswordSuccess ? state.email : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Recuperar acceso', style: textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Text(
                    'Escribe tu correo y te enviaremos un enlace para elegir una contraseña nueva.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  if (sentTo != null) ...[
                    Container(
                      key: const Key('forgot_success_message'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Text(
                        'Si $sentTo tiene una cuenta, te enviamos un enlace. Revisa tu bandeja de entrada y también la carpeta de spam.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.sageDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
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
                  Text('Correo electrónico', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('forgot_email_field'),
                    controller: _emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onSubmitted: (_) => isLoading ? null : _submit(),
                    decoration: const InputDecoration(
                      hintText: 'tucorreo@ejemplo.com',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('forgot_submit_button'),
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
                        : Text(
                            sentTo == null ? 'Enviar enlace' : 'Enviar de nuevo',
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    key: const Key('forgot_to_login_button'),
                    onPressed: isLoading
                        ? null
                        : () => context.go(AppRoutes.login),
                    child: const Text('Volver a iniciar sesión'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
