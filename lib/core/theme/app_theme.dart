import 'package:flutter/material.dart';

abstract final class AppColors {
  static const green = Color(0xFFC5E597);
  static const pink = Color(0xFFFC5494);
  static const yellow = Color(0xFFFCD45C);
  static const cream = Color(0xFFFCFCDC);
  static const paper = Color(0xFFFCFCE4);
  static const ink = Color(0xFF2E2A1F);
}

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.green,
      onPrimary: AppColors.ink,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      tertiary: AppColors.yellow,
      onTertiary: AppColors.ink,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.ink,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.ink,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.ink),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.ink,
        selectedBackgroundColor: AppColors.green,
        selectedForegroundColor: AppColors.ink,
      ),
    ),
    dividerColor: AppColors.yellow,
  );
}
