import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/blocking/domain/repositories/block_repository.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_params.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_user.dart';
import 'package:doulapp/features/blocking/domain/usecases/get_blocked_users.dart';
import 'package:doulapp/features/blocking/domain/usecases/unblock_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockBlockRepository extends Mock implements BlockRepository {}

void main() {
  late MockBlockRepository repository;
  const params = BlockParams(blockerId: 'me', blockedId: 'ana-id');

  setUp(() => repository = MockBlockRepository());

  group('BlockUser', () {
    test('bloquea a otra usuaria', () async {
      when(
        () => repository.blockUser(blockerId: 'me', blockedId: 'ana-id'),
      ).thenAnswer((_) async => const Right(unit));

      expect(await BlockUser(repository)(params), const Right(unit));
      verify(
        () => repository.blockUser(blockerId: 'me', blockedId: 'ana-id'),
      ).called(1);
    });

    test('no deja bloquearse a sí misma y no llama al repositorio', () async {
      final result = await BlockUser(repository)(
        const BlockParams(blockerId: 'me', blockedId: 'me'),
      );

      expect(result, const Left<Failure, dynamic>(CannotBlockSelfFailure()));
      verifyZeroInteractions(repository);
    });

    test('reenvía el fallo del repositorio', () async {
      when(
        () => repository.blockUser(blockerId: 'me', blockedId: 'ana-id'),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      expect(
        await BlockUser(repository)(params),
        const Left<Failure, dynamic>(NetworkFailure()),
      );
    });
  });

  group('UnblockUser', () {
    test('desbloquea', () async {
      when(
        () => repository.unblockUser(blockerId: 'me', blockedId: 'ana-id'),
      ).thenAnswer((_) async => const Right(unit));

      expect(await UnblockUser(repository)(params), const Right(unit));
    });
  });

  group('GetBlockedUsers', () {
    test('devuelve la lista de la usuaria', () async {
      when(
        () => repository.getBlockedUsers('me'),
      ).thenAnswer((_) async => Right([blockedAna]));

      final result = await GetBlockedUsers(repository)('me');

      expect(result.getOrElse(() => []), [blockedAna]);
    });
  });
}
