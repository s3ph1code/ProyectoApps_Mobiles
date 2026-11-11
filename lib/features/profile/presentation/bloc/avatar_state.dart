import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

sealed class AvatarState extends Equatable {
  const AvatarState();

  @override
  List<Object?> get props => [];
}

class AvatarInitial extends AvatarState {
  const AvatarInitial();
}

class AvatarWorking extends AvatarState {
  const AvatarWorking();
}

/// La foto se subió o se quitó; [profile] ya trae la `avatarUrl` nueva.
class AvatarSuccess extends AvatarState {
  final Profile profile;

  const AvatarSuccess(this.profile);

  @override
  List<Object?> get props => [profile];
}

class AvatarFailure extends AvatarState {
  final String message;

  const AvatarFailure(this.message);

  @override
  List<Object?> get props => [message];
}
