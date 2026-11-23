import 'package:equatable/equatable.dart';

import '../../../profile/domain/entities/app_role.dart';

/// Una usuaria tal como la ve la administración: su nombre y sus roles.
class ManagedUser extends Equatable {
  final String id;
  final String? displayName;
  final List<AppRole> roles;

  const ManagedUser({
    required this.id,
    this.displayName,
    this.roles = const [],
  });

  bool get isModerator => roles.contains(AppRole.moderator);
  bool get isAdmin => roles.contains(AppRole.admin);

  /// El rol que más permisos da; toda cuenta es al menos usuaria.
  AppRole get primaryRole => roles.primary ?? AppRole.user;

  ManagedUser withRole(AppRole role) => ManagedUser(
    id: id,
    displayName: displayName,
    roles: roles.contains(role) ? roles : [...roles, role],
  );

  ManagedUser withoutRole(AppRole role) => ManagedUser(
    id: id,
    displayName: displayName,
    roles: [
      for (final r in roles)
        if (r != role) r,
    ],
  );

  @override
  List<Object?> get props => [id, displayName, roles];
}
