import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/avatar_image.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:doulapp/features/profile/domain/usecases/remove_avatar.dart';
import 'package:doulapp/features/profile/domain/usecases/upload_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  final profile = Profile(
    id: 'u',
    displayName: 'Ana',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  final withPhoto = Profile(
    id: 'u',
    displayName: 'Ana',
    avatarUrl: 'https://x/avatars/u/1.png',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  AvatarImage image(String mime, int size) => AvatarImage(
    bytes: Uint8List(size)..fillRange(0, size, 1),
    mimeType: mime,
  );

  setUpAll(() {
    registerFallbackValue(image('image/png', 1));
    registerFallbackValue(profile);
  });
  setUp(() {
    repository = MockProfileRepository();
    when(
      () => repository.uploadAvatar(
        profile: any(named: 'profile'),
        image: any(named: 'image'),
      ),
    ).thenAnswer((_) async => Right(withPhoto));
  });

  Future<Either<Failure, Profile>> upload(AvatarImage img) => UploadAvatar(
    repository,
  )(UploadAvatarParams(profile: profile, image: img));

  group('UploadAvatar', () {
    for (final mime in ['image/jpeg', 'image/png', 'image/webp']) {
      test('acepta $mime', () async {
        final result = await upload(image(mime, 1000));

        expect(result, Right<Failure, Profile>(withPhoto));
        verify(
          () => repository.uploadAvatar(
            profile: profile,
            image: image(mime, 1000),
          ),
        ).called(1);
      });
    }

    test('acepta exactamente 2 MB', () async {
      final result = await upload(image('image/jpeg', UploadAvatar.maxBytes));
      expect(result.isRight(), isTrue);
    });

    test('rechaza más de 2 MB sin subir nada', () async {
      final result = await upload(
        image('image/jpeg', UploadAvatar.maxBytes + 1),
      );

      expect(result, const Left<Failure, Profile>(AvatarTooLargeFailure()));
      verifyNever(
        () => repository.uploadAvatar(
          profile: any(named: 'profile'),
          image: any(named: 'image'),
        ),
      );
    });

    for (final mime in ['image/gif', 'application/pdf', 'unknown']) {
      test('rechaza el tipo $mime', () async {
        final result = await upload(image(mime, 1000));

        expect(
          result,
          const Left<Failure, Profile>(AvatarTypeNotAllowedFailure()),
        );
      });
    }

    test('rechaza un archivo vacío', () async {
      final result = await upload(image('image/png', 0));

      expect(
        result,
        const Left<Failure, Profile>(AvatarTypeNotAllowedFailure()),
      );
    });

    test('propaga el fallo del repositorio', () async {
      when(
        () => repository.uploadAvatar(
          profile: any(named: 'profile'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      expect(
        await upload(image('image/png', 10)),
        const Left<Failure, Profile>(NetworkFailure()),
      );
    });
  });

  group('RemoveAvatar', () {
    test('quita la foto cuando hay una', () async {
      when(
        () => repository.removeAvatar(withPhoto),
      ).thenAnswer((_) async => Right(profile));

      final result = await RemoveAvatar(repository)(
        RemoveAvatarParams(profile: withPhoto),
      );

      expect(result, Right<Failure, Profile>(profile));
    });

    test('sin foto no hace nada ni toca la red', () async {
      final result = await RemoveAvatar(repository)(
        RemoveAvatarParams(profile: profile),
      );

      expect(result, Right<Failure, Profile>(profile));
      verifyNever(() => repository.removeAvatar(any()));
    });
  });
}
