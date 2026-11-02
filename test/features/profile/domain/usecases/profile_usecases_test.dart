import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:doulapp/features/profile/domain/usecases/create_profile.dart';
import 'package:doulapp/features/profile/domain/usecases/get_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  final profile = Profile(
    id: 'uuid-1',
    displayName: 'Ana',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 10),
    updatedAt: DateTime.utc(2026, 1, 10),
  );

  setUp(() {
    repository = MockProfileRepository();
  });

  group('CreateProfile', () {
    test('delega en el repositorio con el id y el nombre', () async {
      when(
        () => repository.createProfile(userId: 'uuid-1', displayName: 'Ana'),
      ).thenAnswer((_) async => Right(profile));

      final result = await CreateProfile(repository)(
        const CreateProfileParams(userId: 'uuid-1', displayName: 'Ana'),
      );

      expect(result, Right<Failure, Profile>(profile));
      verify(
        () => repository.createProfile(userId: 'uuid-1', displayName: 'Ana'),
      ).called(1);
    });

    test('devuelve el Failure del repositorio sin modificarlo', () async {
      when(
        () => repository.createProfile(userId: 'uuid-1', displayName: 'Ana'),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await CreateProfile(repository)(
        const CreateProfileParams(userId: 'uuid-1', displayName: 'Ana'),
      );

      expect(result, const Left<Failure, Profile>(NetworkFailure()));
    });
  });

  group('GetProfile', () {
    test('delega en el repositorio con el id de la usuaria', () async {
      when(() => repository.getProfile('uuid-1'))
          .thenAnswer((_) async => Right(profile));

      final result = await GetProfile(repository)(
        const GetProfileParams(userId: 'uuid-1'),
      );

      expect(result, Right<Failure, Profile>(profile));
      verify(() => repository.getProfile('uuid-1')).called(1);
    });

    test('devuelve el Failure del repositorio sin modificarlo', () async {
      when(() => repository.getProfile('uuid-1'))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await GetProfile(repository)(
        const GetProfileParams(userId: 'uuid-1'),
      );

      expect(result, const Left<Failure, Profile>(ServerFailure()));
    });
  });
}
