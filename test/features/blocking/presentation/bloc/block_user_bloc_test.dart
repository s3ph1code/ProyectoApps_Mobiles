import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_params.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_user.dart';
import 'package:doulapp/features/blocking/domain/usecases/unblock_user.dart';
import 'package:doulapp/features/blocking/presentation/bloc/block_user_bloc.dart';
import 'package:doulapp/features/blocking/presentation/bloc/block_user_event.dart';
import 'package:doulapp/features/blocking/presentation/bloc/block_user_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockBlockUser extends Mock implements BlockUser {}

class MockUnblockUser extends Mock implements UnblockUser {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockBlockUser blockUser;
  late MockUnblockUser unblockUser;

  const me = AuthUser(id: 'me', email: 'me@doulapp.co');
  const params = BlockParams(blockerId: 'me', blockedId: 'ana-id');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(params);
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    blockUser = MockBlockUser();
    unblockUser = MockUnblockUser();
    when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(me));
  });

  BlockUserBloc build() => BlockUserBloc(
    getCurrentUser: getCurrentUser,
    blockUser: blockUser,
    unblockUser: unblockUser,
  );

  blocTest<BlockUserBloc, BlockUserState>(
    'bloquea con la usuaria de la sesión',
    setUp: () =>
        when(() => blockUser(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (bloc) => bloc.add(
      const BlockUserRequested(blockedUserId: 'ana-id', blockedUserName: 'Ana'),
    ),
    expect: () => [
      const BlockUserInProgress(),
      const BlockUserBlocked(
        blockedUserId: 'ana-id',
        blockedUserName: 'Ana',
        sequence: 1,
      ),
    ],
    verify: (_) => verify(() => blockUser(params)).called(1),
  );

  blocTest<BlockUserBloc, BlockUserState>(
    'si falla, avisa con el mensaje del fallo',
    setUp: () => when(
      () => blockUser(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    build: build,
    act: (bloc) => bloc.add(const BlockUserRequested(blockedUserId: 'ana-id')),
    expect: () => [
      const BlockUserInProgress(),
      BlockUserFailure(const NetworkFailure().message, sequence: 1),
    ],
  );

  blocTest<BlockUserBloc, BlockUserState>(
    'sin sesión no intenta bloquear',
    setUp: () => when(
      () => getCurrentUser(any()),
    ).thenAnswer((_) async => const Right(null)),
    build: build,
    act: (bloc) => bloc.add(const BlockUserRequested(blockedUserId: 'ana-id')),
    expect: () => [
      const BlockUserInProgress(),
      BlockUserFailure(const UnauthenticatedFailure().message, sequence: 1),
    ],
    verify: (_) => verifyZeroInteractions(blockUser),
  );

  blocTest<BlockUserBloc, BlockUserState>(
    '«Deshacer» desbloquea',
    setUp: () => when(
      () => unblockUser(any()),
    ).thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (bloc) => bloc.add(const UnblockUserRequested('ana-id')),
    expect: () => [
      const BlockUserInProgress(),
      const BlockUserUnblocked(blockedUserId: 'ana-id', sequence: 1),
    ],
    verify: (_) => verify(() => unblockUser(params)).called(1),
  );
}
