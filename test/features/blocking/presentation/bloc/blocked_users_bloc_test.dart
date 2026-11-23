import 'package:bloc_test/bloc_test.dart';
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
import 'package:doulapp/features/blocking/presentation/bloc/blocked_users_state.dart';
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

  const me = AuthUser(id: 'me', email: 'me@doulapp.co');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const BlockParams(blockerId: 'a', blockedId: 'b'));
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getBlockedUsers = MockGetBlockedUsers();
    blockUser = MockBlockUser();
    unblockUser = MockUnblockUser();
    when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(me));
  });

  BlockedUsersBloc build() => BlockedUsersBloc(
    getCurrentUser: getCurrentUser,
    getBlockedUsers: getBlockedUsers,
    blockUser: blockUser,
    unblockUser: unblockUser,
  );

  blocTest<BlockedUsersBloc, BlockedUsersState>(
    'carga la lista de la usuaria',
    setUp: () => when(
      () => getBlockedUsers('me'),
    ).thenAnswer((_) async => Right([blockedAna])),
    build: build,
    act: (bloc) => bloc.add(const BlockedUsersRequested()),
    expect: () => [
      const BlockedUsersLoading(),
      BlockedUsersLoaded(users: [blockedAna]),
    ],
  );

  blocTest<BlockedUsersBloc, BlockedUsersState>(
    'si la carga falla, muestra el error',
    setUp: () => when(
      () => getBlockedUsers('me'),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    build: build,
    act: (bloc) => bloc.add(const BlockedUsersRequested()),
    expect: () => [
      const BlockedUsersLoading(),
      BlockedUsersFailure(const NetworkFailure().message),
    ],
  );

  blocTest<BlockedUsersBloc, BlockedUsersState>(
    'desbloquear quita la fila al instante y avisa para poder deshacer',
    setUp: () => when(
      () => unblockUser(any()),
    ).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => BlockedUsersLoaded(users: [blockedAnonymous, blockedAna]),
    act: (bloc) => bloc.add(BlockedUserUnblocked(blockedAna)),
    expect: () => [
      BlockedUsersLoaded(
        users: [blockedAnonymous],
        justUnblocked: blockedAna,
        noticeId: 1,
      ),
    ],
  );

  blocTest<BlockedUsersBloc, BlockedUsersState>(
    'si desbloquear falla, la fila vuelve y avisa',
    setUp: () => when(
      () => unblockUser(any()),
    ).thenAnswer((_) async => const Left(ServerFailure())),
    build: build,
    seed: () => BlockedUsersLoaded(users: [blockedAna]),
    act: (bloc) => bloc.add(BlockedUserUnblocked(blockedAna)),
    expect: () => [
      BlockedUsersLoaded(
        users: const [],
        justUnblocked: blockedAna,
        noticeId: 1,
      ),
      BlockedUsersLoaded(
        users: [blockedAna],
        errorMessage: const ServerFailure().message,
        noticeId: 2,
      ),
    ],
  );

  blocTest<BlockedUsersBloc, BlockedUsersState>(
    '«Deshacer» vuelve a bloquear y deja la lista ordenada',
    setUp: () =>
        when(() => blockUser(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => BlockedUsersLoaded(users: [blockedAnonymous]),
    act: (bloc) => bloc.add(BlockedUserRestored(blockedAna)),
    // blockedAnonymous (21/11) es más reciente que blockedAna (20/11).
    expect: () => [
      BlockedUsersLoaded(users: [blockedAnonymous, blockedAna]),
    ],
    verify: (_) => verify(
      () => blockUser(const BlockParams(blockerId: 'me', blockedId: 'ana-id')),
    ).called(1),
  );
}
