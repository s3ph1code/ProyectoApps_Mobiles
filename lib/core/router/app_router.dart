import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/usecases/auth_params.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/sign_in_with_email.dart';
import '../../features/auth/domain/usecases/sign_up_with_email.dart';
import '../../features/profile/domain/usecases/create_profile.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../injection_container.dart';
import '../theme/app_colors.dart';
import '../usecase/usecase.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const profile = '/profile';
}

class AppRouter {
  AppRouter._();

  static GoRouter createRouter({String initialLocation = AppRoutes.login}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const _BridgeLoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const _BridgeRegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const _BridgeOnboardingPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
            child: const ProfilePage(),
          ),
        ),
      ],
    );
  }

  static final GoRouter router = createRouter();
}

class _BridgeLoginPage extends StatefulWidget {
  const _BridgeLoginPage();

  @override
  State<_BridgeLoginPage> createState() => _BridgeLoginPageState();
}

class _BridgeLoginPageState extends State<_BridgeLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await sl<SignInWithEmail>()(
      EmailPasswordParams(email: _email.text, password: _password.text),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) => context.go(AppRoutes.profile),
    );
  }

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
              Text('Bienvenida de nuevo', style: textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Acompañamiento posparto, sin prejuicios.',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 16),
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
                onPressed: _busy ? null : _signIn,
                child: const Text('Entrar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => context.go(AppRoutes.register),
                child: const Text('Crear mi cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BridgeRegisterPage extends StatefulWidget {
  const _BridgeRegisterPage();

  @override
  State<_BridgeRegisterPage> createState() => _BridgeRegisterPageState();
}

class _BridgeRegisterPageState extends State<_BridgeRegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await sl<SignUpWithEmail>()(
      EmailPasswordParams(email: _email.text, password: _password.text),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) => context.go(AppRoutes.onboarding),
    );
  }

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
              Text('Crea tu espacio', style: textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Tu bienestar también importa.',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 16),
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
                decoration: const InputDecoration(
                  hintText: 'Contraseña (mínimo 8 caracteres)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _signUp,
                child: const Text('Crear mi cuenta'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => context.go(AppRoutes.login),
                child: const Text('Ya tengo una cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BridgeOnboardingPage extends StatefulWidget {
  const _BridgeOnboardingPage();

  @override
  State<_BridgeOnboardingPage> createState() => _BridgeOnboardingPageState();
}

class _BridgeOnboardingPageState extends State<_BridgeOnboardingPage> {
  final _displayName = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _saveOnboarding() async {
    final name = _displayName.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe cómo te gustaría que te llamemos.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final userResult = await sl<GetCurrentUser>()(const NoParams());
    if (!mounted) return;

    await userResult.fold(
      (failure) async {
        setState(() {
          _busy = false;
          _error = failure.message;
        });
      },
      (user) async {
        if (user == null) {
          setState(() => _busy = false);
          context.go(AppRoutes.login);
          return;
        }

        final profileResult = await sl<CreateProfile>()(
          CreateProfileParams(userId: user.id, displayName: name),
        );
        if (!mounted) return;
        setState(() => _busy = false);

        profileResult.fold(
          (failure) => setState(() => _error = failure.message),
          (_) => context.go(AppRoutes.profile),
        );
      },
    );
  }

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
              Text('¿Cómo te llamamos?', style: textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Puedes usar tu nombre o un apodo con el que te sientas cómoda.',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _displayName,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Tu nombre'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _saveOnboarding,
                child: const Text('Comenzar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
