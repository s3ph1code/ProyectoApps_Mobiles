import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Marca de Doulapp: un brote sobre un círculo suave.
class DoulappLogo extends StatelessWidget {
  final double size;

  const DoulappLogo({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.beige,
        border: Border.all(
          color: AppColors.sage.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Container(
        width: size * 0.62,
        height: size * 0.62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.sageLight.withValues(alpha: 0.5),
        ),
        child: Icon(
          Icons.spa_rounded,
          size: size * 0.36,
          color: AppColors.sageDark,
        ),
      ),
    );
  }
}
