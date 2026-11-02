/// Rol de una cuenta. Define qué acciones puede hacer en la app.
///
/// Los códigos coinciden con `roles.code` en la base de datos. Todas las
/// cuentas nuevas son [user]; [moderator] y [admin] se asignan desde el
/// panel de Supabase.
enum AppRole {
  user('user', 'Usuaria'),
  moderator('moderator', 'Moderadora'),
  admin('admin', 'Administradora');

  const AppRole(this.code, this.label);

  final String code;

  /// Nombre que ve la usuaria en pantalla.
  final String label;

  /// Puede revisar reportes de la comunidad y gestionar contenido reportado.
  bool get canModerate => this == moderator || this == admin;

  /// Puede administrar cuentas y roles.
  bool get canAdminister => this == admin;

  /// `null` si el código no corresponde a un rol conocido.
  static AppRole? fromCode(String code) {
    for (final role in values) {
      if (role.code == code) return role;
    }
    return null;
  }
}

extension AppRoles on Iterable<AppRole> {
  /// El rol de mayor jerarquía (administradora, luego moderadora, luego
  /// usuaria), o `null` si no hay ninguno.
  AppRole? get primary {
    AppRole? best;
    for (final role in this) {
      if (best == null || role.index > best.index) best = role;
    }
    return best;
  }

  bool get canModerate => any((role) => role.canModerate);

  bool get canAdminister => any((role) => role.canAdminister);
}
