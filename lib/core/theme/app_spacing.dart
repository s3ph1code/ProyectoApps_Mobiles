/// Escala única de espaciado de Doulapp.
///
/// Reemplaza los paddings y separaciones sueltas por una escala coherente.
/// Las pantallas deben consumir estos valores en lugar de números mágicos.
class AppSpacing {
  AppSpacing._();

  /// 4 — separaciones mínimas (icono-texto).
  static const xs = 4.0;

  /// 8 — separación entre elementos muy próximos.
  static const sm = 8.0;

  /// 12 — separación interna de componentes.
  static const md = 12.0;

  /// 16 — separación estándar entre bloques.
  static const lg = 16.0;

  /// 20 — padding interno de tarjetas.
  static const xl = 20.0;

  /// 24 — margen lateral de pantalla.
  static const xxl = 24.0;

  /// 32 — separación entre secciones.
  static const xxxl = 32.0;

  /// Margen horizontal estándar de las pantallas.
  static const screenHMargin = 24.0;
}
