import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:doulapp/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:doulapp/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/domain/usecases/create_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockCreateProfile extends Mock implements CreateProfile {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockCreateProfile createProfile;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
  final profile = Profile(
    id: 'uuid-1',
    displayName: 'Ana',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 1, 10),
    updatedAt: DateTime.utc(2026, 1, 10),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const CreateProfileParams(userId: 'uuid-1', displayName: 'Ana'),
    );
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    createProfile = MockCreateProfile();
  });

  OnboardingBloc buildBloc() => OnboardingBloc(
        getCurrentUser: getCurrentUser,
        createProfile: createProfile,
      );

  group('OnboardingSubmitted', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emite [OnboardingLoading, OnboardingSuccess] cuando guarda el nombre inicial',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(user));
        when(
          () => createProfile(
            const CreateProfileParams(userId: 'uuid-1', displayName: 'Ana'),
          ),
        ).thenAnswer((_) async => Right(profile));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const OnboardingSubmitted(displayName: '  Ana  '),
      ),
      expect: () => [
        const OnboardingLoading(),
        OnboardingSuccess(profile),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emite [OnboardingFailure] si el nombre está vacío',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OnboardingSubmitted(displayName: '   '),
      ),
      expect: () => [
        const OnboardingFailure('Escribe cómo te gustaría que te llamemos.'),
      ],
      verify: (_) {
        verifyNever(() => getCurrentUser(any()));
        verifyNever(() => createProfile(any()));
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emite [OnboardingLoading, OnboardingUnauthenticated] si no hay sesión activa',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const OnboardingSubmitted(displayName: 'Ana'),
      ),
      expect: () => [
        const OnboardingLoading(),
        const OnboardingUnauthenticated(),
      ],
      verify: (_) {
        verifyNever(() => createProfile(any()));
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emite [OnboardingLoading, OnboardingFailure] si falla el guardado del perfil',
      build: () {
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => const Right(user));
        when(() => createProfile(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const OnboardingSubmitted(displayName: 'Ana'),
      ),
      expect: () => [
        const OnboardingLoading(),
        OnboardingFailure(const NetworkFailure().message),
      ],
    );
  });
}
