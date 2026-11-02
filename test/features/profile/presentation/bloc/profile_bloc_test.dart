import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/auth/domain/usecases/sign_out.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/domain/usecases/get_profile.dart';
import 'package:doulapp/features/profile/domain/usecases/get_user_roles.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetProfile extends Mock implements GetProfile {}

class MockGetUserRoles extends Mock implements GetUserRoles {}

class MockSignOut extends Mock implements SignOut {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetProfile getProfile;
  late MockGetUserRoles getUserRoles;
  late MockSignOut signOut;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
  final profile = Profile(
    id: 'uuid-1',
    displayName: 'Ana',
    bio: 'Buscando pequeños momentos de calma.',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 10),
    updatedAt: DateTime.utc(2026, 1, 10),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetProfileParams(userId: 'uuid-1'));
    registerFallbackValue(const GetUserRolesParams(userId: 'uuid-1'));
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getProfile = MockGetProfile();
    getUserRoles = MockGetUserRoles();
    when(() => getUserRoles(any()))
        .thenAnswer((_) async => const Right([AppRole.user]));
    signOut = MockSignOut();
  });

  ProfileBloc buildBloc() => ProfileBloc(
        getCurrentUser: getCurrentUser,
        getProfile: getProfile,
        getUserRoles: getUserRoles,
        signOut: signOut,
      );

  group('ProfileLoadRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileLoaded] cuando hay sesión y perfil',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(user));
        when(() => getProfile(const GetProfileParams(userId: 'uuid-1')))
            .thenAnswer((_) async => Right(profile));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [
        const ProfileLoading(),
        ProfileLoaded(
          profile: profile,
          email: user.email,
          roles: const [AppRole.user],
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'incluye todos los roles de la cuenta y expone el de mayor jerarquía',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(user));
        when(() => getProfile(any())).thenAnswer((_) async => Right(profile));
        when(() => getUserRoles(any())).thenAnswer(
          (_) async => const Right([AppRole.user, AppRole.moderator]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      verify: (bloc) {
        final state = bloc.state as ProfileLoaded;
        expect(state.role, AppRole.moderator);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'muestra el perfil aunque no se puedan consultar los roles',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(user));
        when(() => getProfile(any())).thenAnswer((_) async => Right(profile));
        when(() => getUserRoles(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [
        const ProfileLoading(),
        ProfileLoaded(profile: profile, email: user.email),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileFailure] cuando no hay sesión activa',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [
        const ProfileLoading(),
        ProfileFailure(const UnauthenticatedFailure().message),
      ],
      verify: (_) {
        verifyNever(() => getProfile(any()));
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileFailure] cuando falla la carga del perfil',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(user));
        when(() => getProfile(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [
        const ProfileLoading(),
        ProfileFailure(const NetworkFailure().message),
      ],
    );
  });

  group('ProfileSignOutRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileSignedOut] cuando cierra sesión',
      build: () {
        when(() => signOut(any())).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileSignOutRequested()),
      expect: () => [
        const ProfileLoading(),
        const ProfileSignedOut(),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileFailure] cuando falla el cierre de sesión',
      build: () {
        when(() => signOut(any()))
            .thenAnswer((_) async => const Left(ServerFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileSignOutRequested()),
      expect: () => [
        const ProfileLoading(),
        ProfileFailure(const ServerFailure().message),
      ],
    );
  });
}
