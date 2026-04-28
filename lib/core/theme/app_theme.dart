import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary600,
      onPrimary: AppColors.neutral50,
      secondary: AppColors.accent400,
      onSecondary: AppColors.neutral800,
      error: AppColors.error400,
      onError: AppColors.neutral50,
      surface: isDark ? AppColors.primary800 : AppColors.neutral50,
      onSurface: isDark ? AppColors.neutral50 : AppColors.neutral800,
    );

    final baseText = GoogleFonts.nunitoTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.primary800 : AppColors.neutral50,
      textTheme: baseText,
      cardTheme: CardThemeData(
        color: isDark ? AppColors.primary600 : Colors.white,
        elevation: isDark ? 2 : 1.5,
        shadowColor: AppColors.neutral800.withOpacity(0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.primary600 : Colors.white,
        foregroundColor: isDark ? AppColors.neutral50 : AppColors.neutral800,
        titleTextStyle: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: isDark ? AppColors.neutral50 : AppColors.neutral800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(140, 48),
          backgroundColor: AppColors.primary600,
          foregroundColor: AppColors.neutral50,
          textStyle: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 46),
          foregroundColor: isDark ? AppColors.neutral50 : AppColors.primary600,
          side: BorderSide(
            color: isDark
                ? AppColors.neutral200.withOpacity(0.5)
                : AppColors.primary400.withOpacity(0.7),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.neutral50.withOpacity(0.10) : AppColors.primary50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary400, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? AppColors.primary800 : Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.primary600 : AppColors.primary800,
        contentTextStyle: baseText.bodyMedium?.copyWith(color: AppColors.neutral50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
