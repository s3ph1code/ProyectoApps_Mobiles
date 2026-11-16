/// Quién puede leer una publicación. Los códigos son los de la restricción
/// `visibility` de la tabla `posts`.
enum PostVisibility {
  community(
    'community',
    'Solo la comunidad',
    'La leen solo quienes usan Doulapp.',
  ),
  public('public', 'Pública', 'Se puede compartir fuera de la app.');

  const PostVisibility(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static PostVisibility fromCode(String code) {
    return values.firstWhere((v) => v.code == code, orElse: () => community);
  }
}
