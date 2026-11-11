import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/avatar_image.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/domain/usecases/remove_avatar.dart';
import 'package:doulapp/features/profile/domain/usecases/upload_avatar.dart';
import 'package:doulapp/features/profile/presentation/bloc/avatar_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/avatar_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/avatar_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUploadAvatar extends Mock implements UploadAvatar {}

class MockRemoveAvatar extends Mock implements RemoveAvatar {}

void main() {
  late MockUploadAvatar uploadAvatar;
  late MockRemoveAvatar removeAvatar;

  final profile = Profile(
    id: 'u',
    displayName: 'Ana',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  final updated = Profile(
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

  setUpAll(() {
    registerFallbackValue(UploadAvatarParams(profile: profile, image: image));
    registerFallbackValue(RemoveAvatarParams(profile: profile));
  });

  setUp(() {
    uploadAvatar = MockUploadAvatar();
    removeAvatar = MockRemoveAvatar();
  });

  AvatarBloc build() =>
      AvatarBloc(uploadAvatar: uploadAvatar, removeAvatar: removeAvatar);

  blocTest<AvatarBloc, AvatarState>(
    'sube la foto y emite el perfil actualizado',
    build: () {
      when(() => uploadAvatar(any())).thenAnswer((_) async => Right(updated));
      return build();
    },
    act: (b) => b.add(AvatarUploadRequested(profile: profile, image: image)),
    expect: () => [const AvatarWorking(), AvatarSuccess(updated)],
    verify: (_) => verify(
      () => uploadAvatar(UploadAvatarParams(profile: profile, image: image)),
    ).called(1),
  );

  blocTest<AvatarBloc, AvatarState>(
    'si la imagen no es válida emite el aviso y no cambia nada',
    build: () {
      when(
        () => uploadAvatar(any()),
      ).thenAnswer((_) async => const Left(AvatarTooLargeFailure()));
      return build();
    },
    act: (b) => b.add(AvatarUploadRequested(profile: profile, image: image)),
    expect: () => [
      const AvatarWorking(),
      AvatarFailure(const AvatarTooLargeFailure().message),
    ],
  );

  blocTest<AvatarBloc, AvatarState>(
    'ante un error de red emite el aviso y permite reintentar',
    build: () {
      var calls = 0;
      when(() => uploadAvatar(any())).thenAnswer((_) async {
        calls++;
        return calls == 1 ? const Left(NetworkFailure()) : Right(updated);
      });
      return build();
    },
    act: (b) async {
      b.add(AvatarUploadRequested(profile: profile, image: image));
      await Future<void>.delayed(Duration.zero);
      b.add(AvatarUploadRequested(profile: profile, image: image));
    },
    expect: () => [
      const AvatarWorking(),
      AvatarFailure(const NetworkFailure().message),
      const AvatarWorking(),
      AvatarSuccess(updated),
    ],
  );

  blocTest<AvatarBloc, AvatarState>(
    'ignora una segunda subida mientras la primera sigue en curso',
    build: () {
      when(() => uploadAvatar(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return Right(updated);
      });
      return build();
    },
    act: (b) {
      b.add(AvatarUploadRequested(profile: profile, image: image));
      b.add(AvatarUploadRequested(profile: profile, image: image));
    },
    wait: const Duration(milliseconds: 60),
    expect: () => [const AvatarWorking(), AvatarSuccess(updated)],
    verify: (_) => verify(() => uploadAvatar(any())).called(1),
  );

  blocTest<AvatarBloc, AvatarState>(
    'quita la foto y emite el perfil sin ella',
    build: () {
      when(() => removeAvatar(any())).thenAnswer((_) async => Right(profile));
      return build();
    },
    act: (b) => b.add(AvatarRemoveRequested(updated)),
    expect: () => [const AvatarWorking(), AvatarSuccess(profile)],
  );

  blocTest<AvatarBloc, AvatarState>(
    'si falla quitarla emite el error',
    build: () {
      when(
        () => removeAvatar(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return build();
    },
    act: (b) => b.add(AvatarRemoveRequested(updated)),
    expect: () => [
      const AvatarWorking(),
      AvatarFailure(const ServerFailure().message),
    ],
  );
}
