import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/administration/domain/repositories/role_admin_repository.dart';
import 'package:doulapp/features/administration/domain/usecases/assign_role.dart';
import 'package:doulapp/features/administration/domain/usecases/remove_role.dart';
import 'package:doulapp/features/administration/domain/usecases/resolve_administrator.dart';
import 'package:doulapp/features/administration/domain/usecases/role_params.dart';
import 'package:doulapp/features/administration/domain/usecases/search_users.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:doulapp/features/profile/domain/usecases/get_user_roles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetUserRoles extends Mock implements GetUserRoles {}

class MockRepository extends Mock implements RoleAdminRepository {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetUserRoles getUserRoles;
  late MockRepository repository;
  late ResolveAdministrator resolveAdministrator;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetUserRolesParams(userId: 'x'));
    registerFallbackValue(AppRole.moderator);
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getUserRoles = MockGetUserRoles();
    repository = MockRepository();
    resolveAdministrator = ResolveAdministrator(
      getCurrentUser: getCurrentUser,
      getUserRoles: getUserRoles,
    );
    when(() => getCurrentUser(any())).thenAnswer(
      (_) async => const Right(AuthUser(id: 'root-id', email: 'a@doulapp.co')),
    );
  });

  void rolesAre(List<AppRole> roles) =>
      when(() => getUserRoles(any())).thenAnswer((_) async => Right(roles));

  group('ResolveAdministrator', () {
    test('acepta a una administradora', () async {
      rolesAre([AppRole.user, AppRole.admin]);
      final result = await resolveAdministrator(const NoParams());
      expect(
        result.map((a) => a.userId),
        const Right<Failure, String>('root-id'),
      );
    });

    test('rechaza a una moderadora: moderar no es administrar', () async {
      rolesAre([AppRole.moderator]);
      expect(
        await resolveAdministrator(const NoParams()),
        const Left<Failure, dynamic>(AdminForbiddenFailure()),
      );
    });

    test('rechaza a una usuaria', () async {
      rolesAre([AppRole.user]);
      expect((await resolveAdministrator(const NoParams())).isLeft(), isTrue);
    });

    test('sin sesión no hay acceso', () async {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null));
      expect(
        await resolveAdministrator(const NoParams()),
        const Left<Failure, dynamic>(UnauthenticatedFailure()),
      );
    });

    test('reenvía el fallo al leer los roles', () async {
      when(
        () => getUserRoles(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      expect(
        await resolveAdministrator(const NoParams()),
        const Left<Failure, dynamic>(NetworkFailure()),
      );
    });
  });

  group('SearchUsers', () {
    late SearchUsers search;
    setUp(
      () => search = SearchUsers(
        resolveAdministrator: resolveAdministrator,
        repository: repository,
      ),
    );

    test('sin texto pide el equipo', () async {
      rolesAre([AppRole.admin]);
      when(
        () => repository.searchUsers(''),
      ).thenAnswer((_) async => const Right([lucia, root]));

      final result = await search(const SearchUsersParams());

      expect(result.getOrElse(() => []), [lucia, root]);
    });

    test('busca por el texto sin espacios sobrantes', () async {
      rolesAre([AppRole.admin]);
      when(
        () => repository.searchUsers('Ana'),
      ).thenAnswer((_) async => const Right([ana]));

      final result = await search(const SearchUsersParams(query: '  Ana '));

      expect(result.getOrElse(() => []), [ana]);
    });

    test(
      'una sola letra es demasiado corto y no llega al repositorio',
      () async {
        rolesAre([AppRole.admin]);

        final result = await search(const SearchUsersParams(query: 'a'));

        expect(result, const Left<Failure, dynamic>(SearchTooShortFailure()));
        verifyZeroInteractions(repository);
      },
    );

    test('quien no administra no consulta nada', () async {
      rolesAre([AppRole.moderator]);

      final result = await search(const SearchUsersParams(query: 'Ana'));

      expect(result, const Left<Failure, dynamic>(AdminForbiddenFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('AssignRole', () {
    late AssignRole assign;
    setUp(
      () => assign = AssignRole(
        resolveAdministrator: resolveAdministrator,
        repository: repository,
      ),
    );

    test('asigna el rol de moderadora', () async {
      rolesAre([AppRole.admin]);
      when(
        () => repository.assignRole(userId: 'ana-id', role: AppRole.moderator),
      ).thenAnswer((_) async => const Right(unit));

      final result = await assign(
        const RoleParams(userId: 'ana-id', role: AppRole.moderator),
      );

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('no asigna administradora desde la app', () async {
      rolesAre([AppRole.admin]);

      final result = await assign(
        const RoleParams(userId: 'ana-id', role: AppRole.admin),
      );

      expect(result, const Left<Failure, dynamic>(RoleNotManageableFailure()));
      verifyZeroInteractions(repository);
    });

    test('quien no administra no asigna nada', () async {
      rolesAre([AppRole.moderator]);

      final result = await assign(
        const RoleParams(userId: 'ana-id', role: AppRole.moderator),
      );

      expect(result, const Left<Failure, dynamic>(AdminForbiddenFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('RemoveRole', () {
    late RemoveRole remove;
    setUp(
      () => remove = RemoveRole(
        resolveAdministrator: resolveAdministrator,
        repository: repository,
      ),
    );

    test('quita el rol de moderadora', () async {
      rolesAre([AppRole.admin]);
      when(
        () =>
            repository.removeRole(userId: 'lucia-id', role: AppRole.moderator),
      ).thenAnswer((_) async => const Right(unit));

      final result = await remove(
        const RoleParams(userId: 'lucia-id', role: AppRole.moderator),
      );

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('no puede quitarse a sí misma el rol de administradora', () async {
      rolesAre([AppRole.admin]);

      final result = await remove(
        const RoleParams(userId: 'root-id', role: AppRole.admin),
      );

      expect(
        result,
        const Left<Failure, dynamic>(CannotRemoveOwnAdminFailure()),
      );
      verifyZeroInteractions(repository);
    });

    test('tampoco quita el rol de administradora a otra', () async {
      rolesAre([AppRole.admin]);

      final result = await remove(
        const RoleParams(userId: 'otra-id', role: AppRole.admin),
      );

      expect(result, const Left<Failure, dynamic>(RoleNotManageableFailure()));
    });

    test('quien no administra no quita nada', () async {
      rolesAre([AppRole.user]);

      final result = await remove(
        const RoleParams(userId: 'lucia-id', role: AppRole.moderator),
      );

      expect(result, const Left<Failure, dynamic>(AdminForbiddenFailure()));
      verifyZeroInteractions(repository);
    });
  });
}
