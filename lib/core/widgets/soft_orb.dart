import 'package:flutter/material.dart';

/// Mancha de color difuminada que decora el fondo de las pantallas, como en
/// el diseño. No recibe toques.
class SoftOrb extends StatelessWidget {
  final double size;
  final Color color;

  const SoftOrb({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.68],
          ),
        ),
      ),
    );
  }
}
