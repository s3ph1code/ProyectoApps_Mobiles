import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../../profile/domain/usecases/create_profile.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetCurrentUser getCurrentUser;
  final CreateProfile createProfile;

  OnboardingBloc({
    required this.getCurrentUser,
    required this.createProfile,
  }) : super(const OnboardingInitial()) {
    on<OnboardingSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    final name = event.displayName.trim();
    if (name.isEmpty) {
      emit(
        const OnboardingFailure('Escribe cómo te gustaría que te llamemos.'),
      );
      return;
    }

    emit(const OnboardingLoading());

    final userResult = await getCurrentUser(const NoParams());
    await userResult.fold(
      (failure) async => emit(OnboardingFailure(failure.message)),
      (user) async {
        if (user == null) {
          emit(const OnboardingUnauthenticated());
          return;
        }

        final profileResult = await createProfile(
          CreateProfileParams(userId: user.id, displayName: name),
        );
        profileResult.fold(
          (failure) => emit(OnboardingFailure(failure.message)),
          (profile) => emit(OnboardingSuccess(profile)),
        );
      },
    );
  }
}
