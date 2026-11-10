import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

class EditProfileSubmitted extends EditProfileEvent {
  final Profile profile;
  final String displayName;
  final String? bio;

  const EditProfileSubmitted({
    required this.profile,
    required this.displayName,
    this.bio,
  });

  @override
  List<Object?> get props => [profile, displayName, bio];
}
