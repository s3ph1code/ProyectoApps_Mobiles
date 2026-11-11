import 'package:equatable/equatable.dart';

import '../../domain/entities/avatar_image.dart';
import '../../domain/entities/profile.dart';

sealed class AvatarEvent extends Equatable {
  const AvatarEvent();

  @override
  List<Object?> get props => [];
}

class AvatarUploadRequested extends AvatarEvent {
  final Profile profile;
  final AvatarImage image;

  const AvatarUploadRequested({required this.profile, required this.image});

  @override
  List<Object?> get props => [profile, image];
}

class AvatarRemoveRequested extends AvatarEvent {
  final Profile profile;

  const AvatarRemoveRequested(this.profile);

  @override
  List<Object?> get props => [profile];
}
