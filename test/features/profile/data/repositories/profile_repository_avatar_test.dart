import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:doulapp/features/profile/data/models/profile_model.dart';
import 'package:doulapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/avatar_image.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataSource extends Mock implements ProfileRemoteDataSource {}

void main() {
  late MockDataSource dataSource;
  late ProfileRepositoryImpl repository;

  final current = Profile(
    id: 'u',
    displayName: 'Ana',
    avatarUrl: 'https://x/avatars/u/1.png',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  final saved = ProfileModel(
    id: 'u',
    displayName: 'Ana',
    avatarUrl: 'https://x/avatars/u/2.png',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
  final image = AvatarImage(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'image/png',
  );

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    dataSource = MockDataSource();
    repository = ProfileRepositoryImpl(remoteDataSource: dataSource);
  });

  When<Future<ProfileModel>> stubUpload() => when(
    () => dataSource.uploadAvatar(
      userId: any(named: 'userId'),
      bytes: any(named: 'bytes'),
      mimeType: any(named: 'mimeType'),
      previousAvatarUrl: any(named: 'previousAvatarUrl'),
    ),
  );

  test('uploadAvatar pasa la foto anterior para reemplazarla', () async {
    stubUpload().thenAnswer((_) async => saved);

    final result = await repository.uploadAvatar(
      profile: current,
      image: image,
    );

    expect(result, Right<Failure, Profile>(saved));
    verify(
      () => dataSource.uploadAvatar(
        userId: 'u',
        bytes: image.bytes,
        mimeType: 'image/png',
        previousAvatarUrl: 'https://x/avatars/u/1.png',
      ),
    ).called(1);
  });

  test('uploadAvatar mapea un error de red', () async {
    stubUpload().thenThrow(const NetworkException('sin red'));

    expect(
      await repository.uploadAvatar(profile: current, image: image),
      const Left<Failure, Profile>(NetworkFailure()),
    );
  });

  test('uploadAvatar mapea un rechazo del servidor', () async {
    stubUpload().thenThrow(const ServerException('403'));

    expect(
      await repository.uploadAvatar(profile: current, image: image),
      const Left<Failure, Profile>(ServerFailure()),
    );
  });

  test('removeAvatar devuelve el perfil sin foto', () async {
    final without = ProfileModel(
      id: 'u',
      displayName: 'Ana',
      accountStatus: AccountStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    when(
      () => dataSource.removeAvatar(
        userId: 'u',
        previousAvatarUrl: 'https://x/avatars/u/1.png',
      ),
    ).thenAnswer((_) async => without);

    expect(
      await repository.removeAvatar(current),
      Right<Failure, Profile>(without),
    );
  });
}
