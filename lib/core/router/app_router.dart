import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/forgot_password_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/auth/presentation/bloc/register_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/bloc/edit_profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../injection_container.dart';
import '../widgets/app_shell.dart';
import '../widgets/coming_soon.dart';
import 'session_notifier.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const forMe = '/for-me';
  static const support = '/support';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';

  /// A dónde llega la usuaria después de iniciar sesión o terminar el
  /// onboarding. En el Sprint 1 es el resumen del perfil; cambiar a [home]
  /// basta para que la entrada sea el inicio.
  static const postAuth = profile;
}

class AppRouter {
  AppRouter._();

  /// Rutas a las que puede entrar quien aún no inició sesión.
  static const _publicRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  };

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
      redirect: session == null
          ? null
          : (context, state) => redirectFor(
              isAuthenticated: session.isAuthenticated,
              location: state.matchedLocation,
            ),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => SplashPage(
            nextRoute: session?.isAuthenticated ?? false
                ? AppRoutes.postAuth
                : AppRoutes.login,
          ),
        ),
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
          path: AppRoutes.forgotPassword,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<ForgotPasswordBloc>(),
            child: const ForgotPasswordPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingPage(),
        ),
        // Pantallas principales: comparten el ProfileBloc (saludo e información
        // del perfil) y la navegación inferior.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => BlocProvider(
            create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
            child: AppShell(navigationShell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const HomePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.forMe,
                  builder: (context, state) =>
                      const ComingSoonPage(title: 'Para mí'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.support,
                  builder: (context, state) =>
                      const ComingSoonPage(title: 'Red de apoyo'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) => const ProfilePage(),
                  routes: [
                    // Dentro del shell para compartir el ProfileBloc.
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => BlocProvider(
                        create: (_) => sl<EditProfileBloc>(),
                        child: const EditProfilePage(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
      return AppRoutes.postAuth;
    }
    return null;
  }

  static final GoRouter router = createRouter(
    initialLocation: AppRoutes.splash,
    session: sl<SessionNotifier>(),
  );
}
