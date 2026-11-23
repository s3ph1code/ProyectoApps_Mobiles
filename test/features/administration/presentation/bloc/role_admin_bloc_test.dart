import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/administration/domain/usecases/assign_role.dart';
import 'package:doulapp/features/administration/domain/usecases/remove_role.dart';
import 'package:doulapp/features/administration/domain/usecases/role_params.dart';
import 'package:doulapp/features/administration/domain/usecases/search_users.dart';
import 'package:doulapp/features/administration/presentation/bloc/role_admin_bloc.dart';
import 'package:doulapp/features/administration/presentation/bloc/role_admin_event.dart';
import 'package:doulapp/features/administration/presentation/bloc/role_admin_state.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockSearchUsers extends Mock implements SearchUsers {}

class MockAssignRole extends Mock implements AssignRole {}

class MockRemoveRole extends Mock implements RemoveRole {}

void main() {
  late MockSearchUsers search;
  late MockAssignRole assign;
  late MockRemoveRole remove;

  setUpAll(() {
    registerFallbackValue(const SearchUsersParams());
    registerFallbackValue(
      const RoleParams(userId: 'x', role: AppRole.moderator),
    );
  });

  setUp(() {
    search = MockSearchUsers();
    assign = MockAssignRole();
    remove = MockRemoveRole();
  });

  RoleAdminBloc build() => RoleAdminBloc(
    searchUsers: search,
    assignRole: assign,
    removeRole: remove,
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'al abrir carga el equipo',
    build: () {
      when(
        () => search(const SearchUsersParams()),
      ).thenAnswer((_) async => const Right([lucia, root]));
      return build();
    },
    act: (bloc) => bloc.add(const RoleAdminStarted()),
    expect: () => [
      const RoleAdminState(status: RoleAdminStatus.loading),
      const RoleAdminState(status: RoleAdminStatus.ready, users: [lucia, root]),
    ],
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'buscar guarda el texto y muestra los resultados',
    build: () {
      when(
        () => search(const SearchUsersParams(query: 'Ana')),
      ).thenAnswer((_) async => const Right([ana]));
      return build();
    },
    act: (bloc) => bloc.add(const RoleAdminSearchSubmitted('  Ana ')),
    expect: () => [
      const RoleAdminState(status: RoleAdminStatus.loading, query: 'Ana'),
      const RoleAdminState(
        status: RoleAdminStatus.ready,
        query: 'Ana',
        users: [ana],
      ),
    ],
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'una búsqueda muy corta avisa y conserva la lista',
    build: () {
      when(
        () => search(const SearchUsersParams()),
      ).thenAnswer((_) async => const Right([lucia]));
      when(
        () => search(const SearchUsersParams(query: 'a')),
      ).thenAnswer((_) async => const Left(SearchTooShortFailure()));
      return build();
    },
    act: (bloc) async {
      bloc.add(const RoleAdminStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RoleAdminSearchSubmitted('a'));
    },
    verify: (bloc) {
      expect(bloc.state.status, RoleAdminStatus.ready);
      expect(bloc.state.users, [lucia]);
      expect(bloc.state.notice, const SearchTooShortFailure().message);
      expect(bloc.state.noticeIsError, isTrue);
    },
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'si no es administradora queda como prohibido',
    build: () {
      when(
        () => search(any()),
      ).thenAnswer((_) async => const Left(AdminForbiddenFailure()));
      return build();
    },
    act: (bloc) => bloc.add(const RoleAdminStarted()),
    expect: () => [
      const RoleAdminState(status: RoleAdminStatus.loading),
      const RoleAdminState(status: RoleAdminStatus.forbidden),
    ],
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'un fallo de carga permite reintentar la misma búsqueda',
    build: () {
      var calls = 0;
      when(() => search(any())).thenAnswer(
        (_) async =>
            calls++ == 0 ? const Left(NetworkFailure()) : const Right([ana]),
      );
      return build();
    },
    act: (bloc) async {
      bloc.add(const RoleAdminSearchSubmitted('Ana'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RoleAdminRetried());
    },
    verify: (bloc) {
      expect(bloc.state.status, RoleAdminStatus.ready);
      expect(bloc.state.users, [ana]);
      verify(() => search(const SearchUsersParams(query: 'Ana'))).called(2);
    },
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'hacer moderadora actualiza la fila y avisa',
    build: () {
      when(
        () => search(const SearchUsersParams(query: 'Ana')),
      ).thenAnswer((_) async => const Right([ana]));
      when(() => assign(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const RoleAdminSearchSubmitted('Ana'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RoleAdminModeratorToggled(user: ana, makeModerator: true));
    },
    verify: (bloc) {
      expect(bloc.state.users.single.isModerator, isTrue);
      expect(bloc.state.notice, 'Ana ahora es moderadora.');
      expect(bloc.state.workingUserId, isNull);
      verify(
        () =>
            assign(const RoleParams(userId: 'ana-id', role: AppRole.moderator)),
      ).called(1);
    },
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'quitar el rol actualiza la fila y avisa',
    build: () {
      when(
        () => search(const SearchUsersParams()),
      ).thenAnswer((_) async => const Right([lucia]));
      when(() => remove(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const RoleAdminStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const RoleAdminModeratorToggled(user: lucia, makeModerator: false),
      );
    },
    verify: (bloc) {
      expect(bloc.state.users.single.isModerator, isFalse);
      expect(bloc.state.notice, 'Lucía ya no es moderadora.');
    },
  );

  blocTest<RoleAdminBloc, RoleAdminState>(
    'si falla el cambio, la fila no cambia y se explica',
    build: () {
      when(
        () => search(const SearchUsersParams(query: 'Ana')),
      ).thenAnswer((_) async => const Right([ana]));
      when(
        () => assign(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return build();
    },
    act: (bloc) async {
      bloc.add(const RoleAdminSearchSubmitted('Ana'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RoleAdminModeratorToggled(user: ana, makeModerator: true));
    },
    verify: (bloc) {
      expect(bloc.state.users.single.isModerator, isFalse);
      expect(bloc.state.noticeIsError, isTrue);
      expect(bloc.state.notice, const ServerFailure().message);
      expect(bloc.state.workingUserId, isNull);
    },
  );
}
