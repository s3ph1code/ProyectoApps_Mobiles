import 'package:flutter/material.dart';

/// Paleta central de Doulapp.
///
/// Identidad lavanda-violeta con acentos en rosa cálido sobre crema, pensada
/// para transmitir calma, cercanía y bienestar. Los contrastes de texto sobre
/// fondo cumplen WCAG AA.
///
/// Los nombres históricos (`sage*`) se conservan para no tocar las pantallas
/// que ya los consumen; su valor es ahora la nueva paleta. Los nombres
/// semánticos (`primary`, `secondary`, contenedores) son la forma preferida
/// para el código nuevo.
class AppColors {
  AppColors._();

  // --- Violeta lavanda (acción principal) -----------------------------------
  /// Color primario. Texto blanco encima cumple AA.
  static const sage = Color(0xFF6E5BC6);
  static const sageLight = Color(0xFFB9AAE6);
  static const sageDark = Color(0xFF514599);

  /// Violetas del degradado de las tarjetas destacadas.
  static const sageDeep = Color(0xFF5A49A6);
  static const sageMid = Color(0xFF8475D6);

  // --- Rosa cálido (acento) -------------------------------------------------
  /// Acento rosado para reacciones y detalles. Se usa con texto [ink] encima,
  /// nunca con texto blanco.
  static const blush = Color(0xFFE7A6C6);
  static const blushContainer = Color(0xFFF7DEEB);

  // --- Contenedores suaves --------------------------------------------------
  static const primaryContainer = Color(0xFFE8E2F8);

  // --- Neutros --------------------------------------------------------------
  static const cream = Color(0xFFFBF8FF);
  static const beige = Color(0xFFECE6F7);
  static const surface = Color(0xFFFFFFFF);

  static const ink = Color(0xFF2C2640);
  static const inkSoft = Color(0xFF6C6480);

  /// Texto desactivado y pestañas sin seleccionar.
  static const inkMuted = Color(0xFFA49DB8);

  // --- Semánticos de estado -------------------------------------------------
  static const success = Color(0xFF5FA98A);
  static const warning = Color(0xFFD9A95C);
  static const error = Color(0xFFC85C7A);

  // --- Líneas finas (ink al 9 % y 5,5 %) ------------------------------------
  static const line = Color(0x172C2640);
  static const lineSoft = Color(0x0E2C2640);

  // --- Alias semánticos (preferidos en código nuevo) ------------------------
  static const primary = sage;
  static const secondary = sageDark;
}
