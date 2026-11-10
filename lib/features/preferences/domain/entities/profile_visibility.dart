/// Quién puede ver el perfil de la usuaria. El `code` coincide con el valor
/// guardado en `user_preferences.profile_visibility`.
enum ProfileVisibility {
  public('public'),
  community('community'),
  private('private');

  final String code;

  const ProfileVisibility(this.code);

  static ProfileVisibility fromCode(String code) {
    return ProfileVisibility.values.firstWhere(
      (v) => v.code == code,
      orElse: () => ProfileVisibility.community,
    );
  }
}
