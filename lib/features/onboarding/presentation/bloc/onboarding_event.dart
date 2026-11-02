import 'package:equatable/equatable.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingSubmitted extends OnboardingEvent {
  final String displayName;

  const OnboardingSubmitted({required this.displayName});

  @override
  List<Object?> get props => [displayName];
}
