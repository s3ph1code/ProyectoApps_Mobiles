import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/auth/presentation/bloc/register_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../injection_container.dart';
import 'session_notifier.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const profile = '/profile';
}

class AppRouter {
  AppRouter._();

  /// Rutas a las que puede entrar quien aún no inició sesión.
  static const _publicRoutes = {AppRoutes.login, AppRoutes.register};

  /// [session] activa el control de acceso: sin sesión solo se ven las rutas
  /// públicas, y con sesión iniciada no se vuelve a la pantalla de inicio de
  /// sesión. Sin [session] el router no restringe nada (útil en pruebas).
  static GoRouter createRouter({
    String initialLocation = AppRoutes.login,
    SessionNotifier? session,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: session,
      redirect: session == null ? null : (context, state) => redirectFor(
            isAuthenticated: session.isAuthenticated,
            location: state.matchedLocation,
          ),
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<LoginBloc>(),
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<RegisterBloc>(),
            child: const RegisterPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingPage(),
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

  /// Decide a dónde redirigir según la sesión; `null` deja pasar.
  @visibleForTesting
  static String? redirectFor({
    required bool isAuthenticated,
    required String location,
  }) {
    final isPublic = _publicRoutes.contains(location);

    if (!isAuthenticated && !isPublic) return AppRoutes.login;
    if (isAuthenticated && location == AppRoutes.login) {
      return AppRoutes.profile;
    }
    return null;
  }

  static final GoRouter router = createRouter(session: sl<SessionNotifier>());
}
