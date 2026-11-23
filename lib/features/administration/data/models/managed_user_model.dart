import '../../../profile/domain/entities/app_role.dart';
import '../../domain/entities/managed_user.dart';

class ManagedUserModel extends ManagedUser {
  const ManagedUserModel({required super.id, super.displayName, super.roles});

  /// Fila de `profiles` con sus `user_roles(roles(code))` embebidos.
  factory ManagedUserModel.fromProfileJson(Map<String, dynamic> json) {
    final rows = (json['user_roles'] as List<dynamic>?) ?? const [];
    return ManagedUserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      roles: _rolesFrom(rows),
    );
  }

  static List<AppRole> _rolesFrom(List<dynamic> rows) {
    final roles = <AppRole>[];
    for (final row in rows) {
      final code =
          ((row as Map<String, dynamic>)['roles']
              as Map<String, dynamic>?)?['code'];
      final role = code is String ? AppRole.fromCode(code) : null;
      if (role != null && !roles.contains(role)) roles.add(role);
    }
    return roles;
  }

  /// Agrupa filas de `user_roles` (con `profile` y `roles` embebidos) por
  /// usuaria, conservando el orden en que aparece cada una.
  static List<ManagedUserModel> groupTeamRows(List<Map<String, dynamic>> rows) {
    final byUser = <String, ManagedUserModel>{};
    for (final row in rows) {
      final userId = row['user_id'] as String;
      final code = (row['roles'] as Map<String, dynamic>?)?['code'];
      final role = code is String ? AppRole.fromCode(code) : null;
      final name =
          (row['profile'] as Map<String, dynamic>?)?['display_name'] as String?;

      final current = byUser[userId];
      final roles = [
        ...?current?.roles,
        if (role != null && !(current?.roles.contains(role) ?? false)) role,
      ];
      byUser[userId] = ManagedUserModel(
        id: userId,
        displayName: current?.displayName ?? name,
        roles: roles,
      );
    }
    return byUser.values.toList();
  }
}
