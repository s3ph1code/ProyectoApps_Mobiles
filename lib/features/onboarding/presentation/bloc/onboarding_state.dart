import 'package:equatable/equatable.dart';

import '../../../profile/domain/entities/profile.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingSuccess extends OnboardingState {
  final Profile profile;

  const OnboardingSuccess(this.profile);

  @override
  List<Object?> get props => [profile];
}

class OnboardingUnauthenticated extends OnboardingState {
  const OnboardingUnauthenticated();
}

class OnboardingFailure extends OnboardingState {
  final String message;

  const OnboardingFailure(this.message);

  @override
  List<Object?> get props => [message];
}
