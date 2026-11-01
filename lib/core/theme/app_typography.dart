import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
        displaySmall: GoogleFonts.fraunces(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          height: 1.15,
          color: AppColors.ink,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: AppColors.ink,
        ),
        headlineSmall: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 17,
          height: 1.45,
          color: AppColors.ink,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          height: 1.45,
          color: AppColors.inkSoft,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          height: 1.4,
          color: AppColors.inkSoft,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      );
}
