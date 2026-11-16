/// Qué tipo de publicación es. Los códigos son los que acepta la restricción
/// `post_type` de la tabla `posts`.
enum PostType {
  experience('experience', 'Experiencia'),
  question('question', 'Pregunta'),
  message('message', 'Mensaje');

  const PostType(this.code, this.label);

  final String code;

  /// Etiqueta que lee la usuaria.
  final String label;

  /// Un código desconocido se muestra como mensaje antes que perder la
  /// publicación.
  static PostType fromCode(String code) {
    return values.firstWhere((t) => t.code == code, orElse: () => message);
  }
}
