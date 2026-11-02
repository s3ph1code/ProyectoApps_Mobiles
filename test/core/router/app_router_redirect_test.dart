import 'package:doulapp/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sin sesión', () {
    test('deja ver el inicio de sesión y el registro', () {
      for (final route in [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
      ]) {
        expect(
          AppRouter.redirectFor(isAuthenticated: false, location: route),
          isNull,
          reason: route,
        );
      }
    });

    test('envía al inicio de sesión desde las rutas privadas', () {
      for (final route in [
        AppRoutes.home,
        AppRoutes.forMe,
        AppRoutes.support,
        AppRoutes.profile,
        AppRoutes.onboarding,
      ]) {
        expect(
          AppRouter.redirectFor(isAuthenticated: false, location: route),
          AppRoutes.login,
          reason: route,
        );
      }
    });
  });

  group('con sesión', () {
    test('no vuelve al inicio de sesión', () {
      expect(
        AppRouter.redirectFor(
          isAuthenticated: true,
          location: AppRoutes.login,
        ),
        AppRoutes.home,
      );
    });

    test('deja ver el inicio, el perfil, el onboarding y el registro en curso',
        () {
      for (final route in [
        AppRoutes.splash,
        AppRoutes.home,
        AppRoutes.profile,
        AppRoutes.onboarding,
        AppRoutes.register,
      ]) {
        expect(
          AppRouter.redirectFor(isAuthenticated: true, location: route),
          isNull,
          reason: route,
        );
      }
    });
  });
}
