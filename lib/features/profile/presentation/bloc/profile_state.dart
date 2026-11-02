import 'package:equatable/equatable.dart';

import '../../domain/entities/app_role.dart';
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
  final List<AppRole> roles;

  const ProfileLoaded({
    required this.profile,
    required this.email,
    this.roles = const [],
  });

  /// Rol de mayor jerarquía de la cuenta, o `null` si no se pudo consultar.
  AppRole? get role => roles.primary;

  @override
  List<Object?> get props => [profile, email, roles];
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
