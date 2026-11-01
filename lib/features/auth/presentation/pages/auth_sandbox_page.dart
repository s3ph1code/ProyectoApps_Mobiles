import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/auth_params.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';

/// Pantalla provisional para comprobar contra Supabase que registro, inicio y
/// cierre de sesión funcionan. Se reemplaza por las pantallas definitivas y el
/// router en cuanto existan.
class AuthSandboxPage extends StatefulWidget {
  const AuthSandboxPage({super.key});

  @override
  State<AuthSandboxPage> createState() => _AuthSandboxPageState();
}

class _AuthSandboxPageState extends State<AuthSandboxPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _message;
  bool _isError = false;
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _refreshSession();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _refreshSession() async {
    final result = await sl<GetCurrentUser>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (failure) => _report(failure.message, isError: true),
      (user) => setState(() => _user = user),
    );
  }

  Future<void> _submit(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await action();
    if (mounted) setState(() => _busy = false);
  }

  void _report(String message, {bool isError = false}) {
    setState(() {
      _message = message;
      _isError = isError;
    });
  }

  Future<void> _signUp() => _submit(() async {
        final result = await sl<SignUpWithEmail>()(
          EmailPasswordParams(email: _email.text, password: _password.text),
        );
        if (!mounted) return;
        result.fold(
          (failure) => _report(failure.message, isError: true),
          (user) {
            setState(() => _user = user);
            _report('Cuenta creada para ${user.email}.');
          },
        );
      });

  Future<void> _signIn() => _submit(() async {
        final result = await sl<SignInWithEmail>()(
          EmailPasswordParams(email: _email.text, password: _password.text),
        );
        if (!mounted) return;
        result.fold(
          (failure) => _report(failure.message, isError: true),
          (user) {
            setState(() => _user = user);
            _report('Sesión iniciada como ${user.email}.');
          },
        );
      });

  Future<void> _signOut() => _submit(() async {
        final result = await sl<SignOut>()(const NoParams());
        if (!mounted) return;
        result.fold(
          (failure) => _report(failure.message, isError: true),
          (_) {
            setState(() => _user = null);
            _report('Sesión cerrada.');
          },
        );
      });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Doulapp', style: textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                _user == null
                    ? 'Sin sesión activa.'
                    : 'Sesión activa: ${_user!.email}',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              if (_message != null) ...[
                Text(
                  _message!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _isError ? AppColors.error : AppColors.sageDark,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(hintText: 'Correo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Contraseña'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _signUp,
                child: const Text('Crear mi cuenta'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _signIn,
                child: const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy || _user == null ? null : _signOut,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
