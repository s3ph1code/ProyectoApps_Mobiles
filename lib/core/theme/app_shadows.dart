import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sombras suaves (soft UI) de Doulapp.
///
/// Dos niveles de profundidad con sombras difusas y de baja opacidad, para
/// dar relieve sin endurecer la interfaz. Se aplican manualmente en los
/// contenedores (`BoxDecoration.boxShadow`).
class AppShadows {
  AppShadows._();

  /// Relieve sutil para tarjetas y superficies en reposo.
  static const soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x14514599),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A2C2640),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Relieve mayor para elementos elevados (hojas, diálogos, destacados).
  static const raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x225A49A6),
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
  ];

  /// Sombra de color del acento primario, para botones y tarjetas destacadas.
  static List<BoxShadow> glow(Color color, {double opacity = 0.28}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  /// Color base de las sombras, por si una superficie necesita calcular la suya.
  static const base = AppColors.sageDeep;
}
