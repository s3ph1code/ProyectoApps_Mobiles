import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/theme/app_theme.dart';
import 'package:doulapp/features/administration/domain/entities/managed_user.dart';
import 'package:doulapp/features/administration/domain/usecases/assign_role.dart';
import 'package:doulapp/features/administration/domain/usecases/remove_role.dart';
import 'package:doulapp/features/administration/domain/usecases/role_params.dart';
import 'package:doulapp/features/administration/domain/usecases/search_users.dart';
import 'package:doulapp/features/administration/presentation/bloc/role_admin_bloc.dart';
import 'package:doulapp/features/administration/presentation/bloc/role_admin_event.dart';
import 'package:doulapp/features/administration/presentation/pages/role_admin_page.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late RoleAdminBloc bloc;

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
    when(() => assign(any())).thenAnswer((_) async => const Right(unit));
    when(() => remove(any())).thenAnswer((_) async => const Right(unit));
    when(
      () => search(const SearchUsersParams()),
    ).thenAnswer((_) async => const Right([lucia, root]));
  });

  tearDown(() => bloc.close());

  Future<void> show(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // El bloc se crea dentro de la prueba para que viva en su zona de tiempo.
    bloc = RoleAdminBloc(
      searchUsers: search,
      assignRole: assign,
      removeRole: remove,
    )..add(const RoleAdminStarted());
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: bloc, child: const RoleAdminPage()),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> searchFor(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const Key('admin_search')), text);
    await t.tap(find.byKey(const Key('admin_search_button')));
    await t.pumpAndSettle();
  }

  testWidgets('abre con el equipo y su rol; la administradora no tiene botón', (
    t,
  ) async {
    await show(t);

    expect(find.text('Equipo de moderación'), findsOneWidget);
    expect(find.text('Lucía'), findsOneWidget);
    expect(find.text('Moderadora'), findsOneWidget);
    expect(find.text('Administradora'), findsOneWidget);
    expect(find.byKey(const Key('admin_toggle_lucia-id')), findsOneWidget);
    expect(find.byKey(const Key('admin_toggle_root-id')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('buscar muestra los resultados con «Hacer moderadora»', (
    t,
  ) async {
    when(
      () => search(const SearchUsersParams(query: 'Ana')),
    ).thenAnswer((_) async => const Right([ana]));
    await show(t);

    await searchFor(t, 'Ana');

    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Usuaria'), findsOneWidget);
    expect(find.text('Hacer moderadora'), findsOneWidget);
  });

  testWidgets('hacer moderadora pide confirmación y actualiza la fila', (
    t,
  ) async {
    when(
      () => search(const SearchUsersParams(query: 'Ana')),
    ).thenAnswer((_) async => const Right([ana]));
    await show(t);
    await searchFor(t, 'Ana');

    await t.tap(find.byKey(const Key('admin_toggle_ana-id')));
    await t.pumpAndSettle();
    expect(find.text('¿Hacer moderadora a Ana?'), findsOneWidget);

    await t.tap(find.byKey(const Key('admin_confirm')));
    await t.pumpAndSettle();

    verify(
      () => assign(const RoleParams(userId: 'ana-id', role: AppRole.moderator)),
    ).called(1);
    expect(find.text('Quitar rol'), findsOneWidget);
    expect(find.text('Ana ahora es moderadora.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('cancelar la confirmación no cambia nada', (t) async {
    await show(t);

    await t.tap(find.byKey(const Key('admin_toggle_lucia-id')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('admin_cancel')));
    await t.pumpAndSettle();

    verifyNever(() => remove(any()));
    expect(find.text('Moderadora'), findsOneWidget);
  });

  testWidgets('quitar el rol actualiza la etiqueta', (t) async {
    await show(t);

    await t.tap(find.byKey(const Key('admin_toggle_lucia-id')));
    await t.pumpAndSettle();
    expect(find.text('¿Quitar el rol de moderadora a Lucía?'), findsOneWidget);
    await t.tap(find.byKey(const Key('admin_confirm')));
    await t.pumpAndSettle();

    verify(
      () =>
          remove(const RoleParams(userId: 'lucia-id', role: AppRole.moderator)),
    ).called(1);
    expect(find.text('Lucía ya no es moderadora.'), findsOneWidget);
    expect(find.text('Moderadora'), findsNothing);
  });

  testWidgets('si falla el cambio avisa y el estado no cambia', (t) async {
    when(
      () => remove(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    await show(t);

    await t.tap(find.byKey(const Key('admin_toggle_lucia-id')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('admin_confirm')));
    await t.pumpAndSettle();

    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(find.text('Moderadora'), findsOneWidget);
  });

  testWidgets('una búsqueda de una letra avisa sin vaciar la lista', (t) async {
    when(
      () => search(const SearchUsersParams(query: 'a')),
    ).thenAnswer((_) async => const Left(SearchTooShortFailure()));
    await show(t);

    await searchFor(t, 'a');

    expect(find.text(const SearchTooShortFailure().message), findsOneWidget);
    expect(find.text('Lucía'), findsOneWidget);
  });

  testWidgets('sin resultados lo explica, con la nota de perfiles privados', (
    t,
  ) async {
    when(
      () => search(const SearchUsersParams(query: 'Zoe')),
    ).thenAnswer((_) async => const Right(<ManagedUser>[]));
    await show(t);

    await searchFor(t, 'Zoe');

    expect(find.text('No encontramos usuarias con ese nombre'), findsOneWidget);
    expect(find.textContaining('perfil privado'), findsOneWidget);
  });

  testWidgets('sin equipo invita a buscar', (t) async {
    when(
      () => search(const SearchUsersParams()),
    ).thenAnswer((_) async => const Right(<ManagedUser>[]));
    await show(t);

    expect(find.text('Aún no hay moderadoras'), findsOneWidget);
  });

  testWidgets('si falla la carga permite reintentar', (t) async {
    var calls = 0;
    when(() => search(const SearchUsersParams())).thenAnswer(
      (_) async =>
          calls++ == 0 ? const Left(NetworkFailure()) : const Right([lucia]),
    );
    await show(t);

    expect(find.text('No pudimos cargar la lista'), findsOneWidget);
    await t.tap(find.byKey(const Key('admin_retry')));
    await t.pumpAndSettle();

    expect(find.text('Lucía'), findsOneWidget);
  });

  testWidgets('sin permiso explica y no ofrece buscar', (t) async {
    when(
      () => search(any()),
    ).thenAnswer((_) async => const Left(AdminForbiddenFailure()));
    await show(t);

    expect(find.text('Esta sección es para administración'), findsOneWidget);
    expect(find.byKey(const Key('admin_search')), findsNothing);
  });

  testWidgets('un nombre largo y uno vacío no rompen el diseño', (t) async {
    when(() => search(const SearchUsersParams())).thenAnswer(
      (_) async => const Right([
        ManagedUser(
          id: 'long-id',
          displayName:
              'Una usuaria con un nombre larguísimo que no cabe en una sola línea',
          roles: [AppRole.user, AppRole.moderator],
        ),
        anonymous,
      ]),
    );
    await show(t);

    expect(find.text('Usuaria de Doulapp'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
