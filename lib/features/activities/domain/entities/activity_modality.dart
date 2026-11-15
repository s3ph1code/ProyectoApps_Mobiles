/// Cómo se vive un microdescanso. Los códigos son los que acepta la
/// restricción `modality` de la tabla `activities`.
enum ActivityModality {
  read('read', 'Leer'),
  listen('listen', 'Escuchar'),
  watch('watch', 'Ver'),
  practice('do', 'Hacer');

  const ActivityModality(this.code, this.label);

  final String code;

  /// Etiqueta que lee la usuaria.
  final String label;

  /// Un código que no reconocemos se muestra como «Hacer» antes que dejar la
  /// actividad fuera de la lista.
  static ActivityModality fromCode(String code) {
    return values.firstWhere((m) => m.code == code, orElse: () => practice);
  }
}
