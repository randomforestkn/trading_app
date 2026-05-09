import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'SF Pro Display';

  static const TextTheme darkTextTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      height: 1.05,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: AppColors.textMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: Colors.white,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textMuted,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 16,
    height: 1.15,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    color: Colors.white,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textMuted,
  );
}
