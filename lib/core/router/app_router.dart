import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/activities/domain/entities/activity.dart';
import '../../features/activities/domain/entities/activity_modality.dart';
import '../../features/activities/presentation/bloc/activities_bloc.dart';
import '../../features/activities/presentation/bloc/activities_event.dart';
import '../../features/activities/presentation/bloc/activity_session_bloc.dart';
import '../../features/activities/presentation/bloc/activity_session_event.dart';
import '../../features/activities/presentation/pages/activities_page.dart';
import '../../features/activities/presentation/pages/activity_session_page.dart';
import '../../features/auth/presentation/bloc/forgot_password_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/auth/presentation/bloc/register_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/preferences/presentation/bloc/preferences_bloc.dart';
import '../../features/preferences/presentation/bloc/preferences_event.dart';
import '../../features/preferences/presentation/pages/notifications_page.dart';
import '../../features/preferences/presentation/pages/privacy_page.dart';
import '../../features/profile/presentation/bloc/avatar_bloc.dart';
import '../../features/profile/presentation/bloc/edit_profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/wellbeing/presentation/bloc/mood_checkin_bloc.dart';
import '../../features/wellbeing/presentation/bloc/mood_history_bloc.dart';
import '../../features/wellbeing/presentation/bloc/mood_history_event.dart';
import '../../features/wellbeing/presentation/pages/mood_checkin_page.dart';
import '../../features/wellbeing/presentation/pages/mood_history_page.dart';
import '../../injection_container.dart';
import '../widgets/app_shell.dart';
import '../widgets/placeholder_page.dart';
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
  static const activities = '/activities';
  static const moodCheckin = '/wellbeing/checkin';
  static const moodHistory = '/wellbeing/history';
  static const needs = '/wellbeing/needs';
  static const recommendations = '/wellbeing/recommendations';
  static const activityDetail = '/activities/:id';
  static const activitySession = '/activities/:id/session';
  static const savedActivities = '/activities/saved';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const notifications = '/profile/notifications';
  static const privacy = '/profile/privacy';

  static String activityDetailPath(String id) => '/activities/$id';
  static String activitySessionPath(String id) => '/activities/$id/session';

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
        GoRoute(
          path: AppRoutes.activities,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                sl<ActivitiesBloc>()..add(const ActivitiesRequested()),
            child: const ActivitiesPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.moodCheckin,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<MoodCheckinBloc>(),
            child: const MoodCheckinPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.moodHistory,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                sl<MoodHistoryBloc>()..add(const MoodHistoryRequested()),
            child: const MoodHistoryPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.needs,
          builder: (context, state) => const FeaturePlaceholderPage(
            title: '«No sé qué necesito»',
            subtitle:
                'Elige cómo te sientes ahora para recibir recomendaciones que te acompañen con cariño.',
            icon: Icons.lightbulb_outline_rounded,
          ),
        ),
        GoRoute(
          path: AppRoutes.recommendations,
          builder: (context, state) => const FeaturePlaceholderPage(
            title: 'Recomendaciones',
            subtitle:
                'Sugerencias de pausas y apoyo pensadas para lo que necesitas hoy.',
            icon: Icons.recommend_outlined,
          ),
        ),
        GoRoute(
          path: AppRoutes.savedActivities,
          builder: (context, state) => const FeaturePlaceholderPage(
            title: 'Actividades guardadas',
            subtitle:
                'Tus pausas favoritas guardadas para acceder a ellas rápidamente.',
            icon: Icons.bookmark_border_rounded,
          ),
        ),
        GoRoute(
          path: AppRoutes.activityDetail,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return FeaturePlaceholderPage(
              title: 'Detalle de la pausa',
              subtitle:
                  'Instrucciones paso a paso y duración de la actividad ($id).',
              icon: Icons.menu_book_outlined,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.activitySession,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final activity = state.extra is Activity
                ? state.extra as Activity
                : Activity(
                    id: id,
                    categoryId: '',
                    title: 'Pausa breve',
                    description: 'Tómate este momento a tu propio ritmo.',
                    modality: ActivityModality.practice,
                    durationMinutes: 5,
                  );

            return BlocProvider(
              create: (_) => sl<ActivitySessionBloc>()
                ..add(ActivitySessionStarted(activity)),
              child: ActivitySessionPage(activity: activity),
            );
          },
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
                  builder: (context, state) => BlocProvider(
                    create: (_) =>
                        sl<ActivitiesBloc>()..add(const ActivitiesRequested()),
                    child: const ActivitiesPage(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.support,
                  builder: (context, state) => const SupportPage(),
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
                      builder: (context, state) => MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => sl<EditProfileBloc>()),
                          BlocProvider(create: (_) => sl<AvatarBloc>()),
                        ],
                        child: const EditProfilePage(),
                      ),
                    ),
                    GoRoute(
                      path: 'notifications',
                      builder: (context, state) => BlocProvider(
                        create: (_) =>
                            sl<PreferencesBloc>()
                              ..add(const PreferencesLoadRequested()),
                        child: const NotificationsPage(),
                      ),
                    ),
                    GoRoute(
                      path: 'privacy',
                      builder: (context, state) => BlocProvider(
                        create: (_) =>
                            sl<PreferencesBloc>()
                              ..add(const PreferencesLoadRequested()),
                        child: const PrivacyPage(),
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
