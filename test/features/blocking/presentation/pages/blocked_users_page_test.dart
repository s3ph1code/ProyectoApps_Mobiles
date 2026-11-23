import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_params.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_user.dart';
import 'package:doulapp/features/blocking/domain/usecases/get_blocked_users.dart';
import 'package:doulapp/features/blocking/domain/usecases/unblock_user.dart';
import 'package:doulapp/features/blocking/presentation/bloc/blocked_users_bloc.dart';
import 'package:doulapp/features/blocking/presentation/bloc/blocked_users_event.dart';
import 'package:doulapp/features/blocking/presentation/pages/blocked_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetBlockedUsers extends Mock implements GetBlockedUsers {}

class MockBlockUser extends Mock implements BlockUser {}

class MockUnblockUser extends Mock implements UnblockUser {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetBlockedUsers getBlockedUsers;
  late MockBlockUser blockUser;
  late MockUnblockUser unblockUser;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const BlockParams(blockerId: 'a', blockedId: 'b'));
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    when(() => getCurrentUser(any())).thenAnswer(
      (_) async => const Right(AuthUser(id: 'me', email: 'me@doulapp.co')),
    );
    getBlockedUsers = MockGetBlockedUsers();
    blockUser = MockBlockUser();
    unblockUser = MockUnblockUser();
    when(() => unblockUser(any())).thenAnswer((_) async => const Right(unit));
    when(() => blockUser(any())).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() => bloc.close());

  Future<void> show(WidgetTester t, {bool settle = true}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // El bloc se crea dentro de la prueba para que viva en su zona de tiempo.
    bloc = BlockedUsersBloc(
      getCurrentUser: getCurrentUser,
      getBlockedUsers: getBlockedUsers,
      blockUser: blockUser,
      unblockUser: unblockUser,
    )..add(const BlockedUsersRequested());
    await t.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const BlockedUsersPage()),
      ),
    );
    if (settle) {
      await t.pumpAndSettle();
    } else {
      await t.pump();
    }
  }

  testWidgets('muestra la carga mientras llega la lista', (t) async {
    when(() => getBlockedUsers('me')).thenAnswer(
      (_) =>
          Future.delayed(const Duration(seconds: 1), () => Right([blockedAna])),
    );

    await show(t, settle: false);

    expect(find.byKey(const Key('blocked_loading')), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('blocked_list')), findsOneWidget);
  });

  testWidgets('lista a las bloqueadas; sin nombre dice «Usuaria de Doulapp»', (
    t,
  ) async {
    when(
      () => getBlockedUsers('me'),
    ).thenAnswer((_) async => Right([blockedAnonymous, blockedAna]));

    await show(t);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Usuaria de Doulapp'), findsOneWidget);
    expect(find.byKey(const Key('unblock_ana-id')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('sin bloqueadas muestra un mensaje amable', (t) async {
    when(() => getBlockedUsers('me')).thenAnswer((_) async => const Right([]));

    await show(t);

    expect(find.text('No has bloqueado a nadie'), findsOneWidget);
    expect(find.byKey(const Key('blocked_list')), findsNothing);
  });

  testWidgets('si falla la carga permite reintentar', (t) async {
    var calls = 0;
    when(() => getBlockedUsers('me')).thenAnswer((_) async {
      calls++;
      return calls == 1 ? const Left(NetworkFailure()) : Right([blockedAna]);
    });

    await show(t);
    expect(find.text('No pudimos cargar la lista'), findsOneWidget);

    await t.tap(find.byKey(const Key('blocked_retry')));
    await t.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('desbloquear quita la fila y «Deshacer» la devuelve', (t) async {
    when(
      () => getBlockedUsers('me'),
    ).thenAnswer((_) async => Right([blockedAna]));
    await show(t);

    await t.tap(find.byKey(const Key('unblock_ana-id')));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('blocked_ana-id')), findsNothing);
    expect(find.text('Desbloqueaste a Ana'), findsOneWidget);
    verify(
      () =>
          unblockUser(const BlockParams(blockerId: 'me', blockedId: 'ana-id')),
    ).called(1);

    await t.tap(find.text('Deshacer'));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('blocked_ana-id')), findsOneWidget);
    verify(
      () => blockUser(const BlockParams(blockerId: 'me', blockedId: 'ana-id')),
    ).called(1);
  });

  testWidgets('si desbloquear falla, la fila vuelve y se explica', (t) async {
    when(
      () => getBlockedUsers('me'),
    ).thenAnswer((_) async => Right([blockedAna]));
    when(
      () => unblockUser(any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    await show(t);

    await t.tap(find.byKey(const Key('unblock_ana-id')));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('blocked_ana-id')), findsOneWidget);
    expect(find.text(const ServerFailure().message), findsOneWidget);
  });
}

late BlockedUsersBloc bloc;
