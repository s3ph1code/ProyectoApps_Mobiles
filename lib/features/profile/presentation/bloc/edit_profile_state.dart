import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

sealed class EditProfileState extends Equatable {
  const EditProfileState();

  @override
  List<Object?> get props => [];
}

class EditProfileInitial extends EditProfileState {
  const EditProfileInitial();
}

class EditProfileSaving extends EditProfileState {
  const EditProfileSaving();
}

class EditProfileSuccess extends EditProfileState {
  final Profile profile;

  const EditProfileSuccess(this.profile);

  @override
  List<Object?> get props => [profile];
}

class EditProfileFailure extends EditProfileState {
  final String message;

  const EditProfileFailure(this.message);

  @override
  List<Object?> get props => [message];
}
