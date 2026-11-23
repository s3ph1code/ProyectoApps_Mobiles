import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/moderation/domain/usecases/resolve_moderator.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:doulapp/features/profile/domain/usecases/get_user_roles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetUserRoles extends Mock implements GetUserRoles {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetUserRoles getUserRoles;
  late ResolveModerator resolveModerator;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetUserRolesParams(userId: 'x'));
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getUserRoles = MockGetUserRoles();
    resolveModerator = ResolveModerator(
      getCurrentUser: getCurrentUser,
      getUserRoles: getUserRoles,
    );
    when(() => getCurrentUser(any())).thenAnswer(
      (_) async => const Right(AuthUser(id: 'u', email: 'u@doulapp.co')),
    );
  });

  Future<String?> guardFor(List<AppRole> roles) {
    when(() => getUserRoles(any())).thenAnswer((_) async => Right(roles));
    return AppRouter.moderationRedirect(resolveModerator);
  }

  group('guardia de la ruta de moderación', () {
    test('una moderadora entra', () async {
      expect(await guardFor([AppRole.moderator]), isNull);
    });

    test('una administradora entra', () async {
      expect(await guardFor([AppRole.user, AppRole.admin]), isNull);
    });

    test('una usuaria es redirigida al perfil', () async {
      expect(await guardFor([AppRole.user]), AppRoutes.profile);
    });

    test('si no se pueden leer los roles, nadie entra', () async {
      when(
        () => getUserRoles(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      expect(
        await AppRouter.moderationRedirect(resolveModerator),
        AppRoutes.profile,
      );
    });

    test('sin sesión tampoco', () async {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null));
      expect(
        await AppRouter.moderationRedirect(resolveModerator),
        AppRoutes.profile,
      );
    });
  });

  test('las rutas de moderación cuelgan del perfil', () {
    expect(AppRoutes.moderation, startsWith(AppRoutes.profile));
    expect(AppRoutes.reportDetail, startsWith(AppRoutes.moderation));
  });
}
