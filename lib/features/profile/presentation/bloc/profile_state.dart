import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final Profile profile;
  final String email;

  const ProfileLoaded({
    required this.profile,
    required this.email,
  });

  @override
  List<Object?> get props => [profile, email];
}

class ProfileFailure extends ProfileState {
  final String message;

  const ProfileFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileSignedOut extends ProfileState {
  const ProfileSignedOut();
}
