import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:doulapp/features/profile/domain/usecases/update_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;
  late UpdateProfile useCase;

  final current = Profile(
    id: 'uuid-1',
    displayName: 'Ana',
    avatarUrl: 'https://ejemplo.com/ana.png',
    bio: 'Antes',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 10),
    updatedAt: DateTime.utc(2026, 1, 10),
  );

  setUpAll(() {
    registerFallbackValue(current);
  });

  setUp(() {
    repository = MockProfileRepository();
    useCase = UpdateProfile(repository);
    when(() => repository.updateProfile(any())).thenAnswer(
      (invocation) async => Right(invocation.positionalArguments.first as Profile),
    );
  });

  test('guarda el nombre y la bio recortados y conserva el resto', () async {
    final result = await useCase(
      UpdateProfileParams(
        profile: current,
        displayName: '  Ana María  ',
        bio: '  Un día a la vez.  ',
      ),
    );

    final saved = result.getOrElse(() => throw StateError('sin perfil'));
    expect(saved.displayName, 'Ana María');
    expect(saved.bio, 'Un día a la vez.');
    expect(saved.id, current.id);
    expect(saved.avatarUrl, current.avatarUrl);
    expect(saved.accountStatus, current.accountStatus);
    verify(() => repository.updateProfile(any())).called(1);
  });

  test('una bio vacía o solo con espacios se guarda como ausente', () async {
    for (final bio in ['', '   ', null]) {
      final result = await useCase(
        UpdateProfileParams(profile: current, displayName: 'Ana', bio: bio),
      );
      expect(result.getOrElse(() => current).bio, isNull, reason: 'bio: $bio');
    }
  });

  test('rechaza un nombre vacío sin llamar al repositorio', () async {
    final result = await useCase(
      UpdateProfileParams(profile: current, displayName: '   ', bio: 'Hola'),
    );

    expect(result, const Left<Failure, Profile>(MissingNameFailure()));
    verifyNever(() => repository.updateProfile(any()));
  });

  test('acepta un nombre de 100 caracteres y rechaza uno de 101', () async {
    final ok = await useCase(
      UpdateProfileParams(profile: current, displayName: 'a' * 100),
    );
    expect(ok.isRight(), isTrue);

    final tooLong = await useCase(
      UpdateProfileParams(profile: current, displayName: 'a' * 101),
    );
    expect(tooLong, const Left<Failure, Profile>(NameTooLongFailure()));
  });

  test('acepta una bio de 280 caracteres y rechaza una de 281', () async {
    final ok = await useCase(
      UpdateProfileParams(
        profile: current,
        displayName: 'Ana',
        bio: 'b' * 280,
      ),
    );
    expect(ok.isRight(), isTrue);

    final tooLong = await useCase(
      UpdateProfileParams(
        profile: current,
        displayName: 'Ana',
        bio: 'b' * 281,
      ),
    );
    expect(tooLong, const Left<Failure, Profile>(BioTooLongFailure()));
    verify(() => repository.updateProfile(any())).called(1);
  });

  test('devuelve el Failure del repositorio sin modificarlo', () async {
    when(
      () => repository.updateProfile(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(
      UpdateProfileParams(profile: current, displayName: 'Ana'),
    );

    expect(result, const Left<Failure, Profile>(NetworkFailure()));
  });
}
