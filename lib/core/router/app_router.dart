import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/auth/presentation/bloc/register_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../injection_container.dart';

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
          builder: (context, state) => BlocProvider(
            create: (_) => sl<OnboardingBloc>(),
            child: const OnboardingPage(),
          ),
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
