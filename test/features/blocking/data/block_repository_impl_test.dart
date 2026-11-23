import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/blocking/data/datasources/block_remote_datasource.dart';
import 'package:doulapp/features/blocking/data/repositories/block_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockDataSource extends Mock implements BlockRemoteDataSource {}

void main() {
  late MockDataSource dataSource;
  late BlockRepositoryImpl repository;

  setUp(() {
    dataSource = MockDataSource();
    repository = BlockRepositoryImpl(remoteDataSource: dataSource);
  });

  test('getBlockedUsers devuelve la lista', () async {
    when(
      () => dataSource.getBlockedUsers('me'),
    ).thenAnswer((_) async => [blockedModelAna]);

    final result = await repository.getBlockedUsers('me');

    expect(result.getOrElse(() => []), [blockedModelAna]);
  });

  test('blockUser y unblockUser devuelven unit', () async {
    when(
      () => dataSource.blockUser(blockerId: 'me', blockedId: 'a'),
    ).thenAnswer((_) async {});
    when(
      () => dataSource.unblockUser(blockerId: 'me', blockedId: 'a'),
    ).thenAnswer((_) async {});

    expect(
      await repository.blockUser(blockerId: 'me', blockedId: 'a'),
      const Right<Failure, Unit>(unit),
    );
    expect(
      await repository.unblockUser(blockerId: 'me', blockedId: 'a'),
      const Right<Failure, Unit>(unit),
    );
  });

  group('mapea las excepciones a fallos', () {
    Future<Either<Failure, Unit>> blockWith(Object error) {
      when(
        () => dataSource.blockUser(blockerId: 'me', blockedId: 'a'),
      ).thenThrow(error);
      return repository.blockUser(blockerId: 'me', blockedId: 'a');
    }

    test('red', () async {
      expect(
        await blockWith(const NetworkException('sin red')),
        const Left<Failure, Unit>(NetworkFailure()),
      );
    });

    test('servidor', () async {
      expect(
        await blockWith(const ServerException('boom')),
        const Left<Failure, Unit>(ServerFailure()),
      );
    });

    test('sesión', () async {
      expect(
        await blockWith(const UnauthenticatedException()),
        const Left<Failure, Unit>(UnauthenticatedFailure()),
      );
    });

    test('inesperado', () async {
      expect(
        await blockWith(StateError('x')),
        const Left<Failure, Unit>(UnexpectedFailure()),
      );
    });
  });
}
