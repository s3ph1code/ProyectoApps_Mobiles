import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/domain/usecases/update_profile.dart';
import 'package:doulapp/features/profile/presentation/bloc/edit_profile_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/edit_profile_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/edit_profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateProfile extends Mock implements UpdateProfile {}

void main() {
  late MockUpdateProfile updateProfile;

  final current = Profile(
    id: 'uuid-1',
    displayName: 'Ana',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 10),
    updatedAt: DateTime.utc(2026, 1, 10),
  );
  final updated = Profile(
    id: 'uuid-1',
    displayName: 'Ana María',
    bio: 'Hola',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 10),
    updatedAt: DateTime.utc(2026, 2, 1),
  );

  setUpAll(() {
    registerFallbackValue(UpdateProfileParams(profile: current, displayName: ''));
  });

  setUp(() {
    updateProfile = MockUpdateProfile();
  });

  EditProfileSubmitted submitEvent() => EditProfileSubmitted(
    profile: current,
    displayName: 'Ana María',
    bio: 'Hola',
  );

  blocTest<EditProfileBloc, EditProfileState>(
    'emite guardando y éxito con el perfil actualizado',
    build: () {
      when(() => updateProfile(any())).thenAnswer((_) async => Right(updated));
      return EditProfileBloc(updateProfile: updateProfile);
    },
    act: (bloc) => bloc.add(submitEvent()),
    expect: () => [const EditProfileSaving(), EditProfileSuccess(updated)],
    verify: (_) {
      verify(
        () => updateProfile(
          UpdateProfileParams(
            profile: current,
            displayName: 'Ana María',
            bio: 'Hola',
          ),
        ),
      ).called(1);
    },
  );

  blocTest<EditProfileBloc, EditProfileState>(
    'emite guardando y el mensaje del Failure si algo falla',
    build: () {
      when(
        () => updateProfile(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return EditProfileBloc(updateProfile: updateProfile);
    },
    act: (bloc) => bloc.add(submitEvent()),
    expect: () => [
      const EditProfileSaving(),
      EditProfileFailure(const NetworkFailure().message),
    ],
  );

  blocTest<EditProfileBloc, EditProfileState>(
    'permite reintentar después de un error',
    build: () {
      var calls = 0;
      when(() => updateProfile(any())).thenAnswer((_) async {
        calls++;
        return calls == 1 ? const Left(ServerFailure()) : Right(updated);
      });
      return EditProfileBloc(updateProfile: updateProfile);
    },
    act: (bloc) async {
      bloc.add(submitEvent());
      await Future<void>.delayed(Duration.zero);
      bloc.add(submitEvent());
    },
    expect: () => [
      const EditProfileSaving(),
      EditProfileFailure(const ServerFailure().message),
      const EditProfileSaving(),
      EditProfileSuccess(updated),
    ],
  );
}
