import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PijarEdu brand colors (see PRD section 16).
class AppColors {
  static const primary = Color(0xFF4540D9);
  static const primaryLight = Color(0xFF5B57E0);
  static const spark = Color(0xFFFFC93C);
  static const background = Color(0xFFEEF0FF);
  static const surface = Colors.white;
  static const textDark = Color(0xFF1E1B4B);
  static const textGrey = Color(0xFF6B6E92);
  static const outline = Color(0xFFD9DCF5);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFE5484D);

  // Pastel tiles used behind icons (menu grid, stat cards).
  static const tilePurple = Color(0xFFE6E3FF);
  static const tilePink = Color(0xFFFFE4EC);
  static const tileYellow = Color(0xFFFFF1C2);
  static const tileGreen = Color(0xFFDDF8E4);
  static const tileBlue = Color(0xFFDCEBFF);
}

class AppRadius {
  static const double card = 20;
  static const double button = 18;
  static const double tile = 14;
  static const double sheet = 28;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.spark,
    surface: AppColors.surface,
    error: AppColors.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
  );

  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
    bodyColor: AppColors.textDark,
    displayColor: AppColors.textDark,
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.textGrey),
      prefixIconColor: AppColors.textGrey,
      suffixIconColor: AppColors.textGrey,
      border: inputBorder(AppColors.outline),
      enabledBorder: inputBorder(AppColors.outline),
      focusedBorder: inputBorder(AppColors.primary, 1.8),
      errorBorder: inputBorder(AppColors.danger),
      focusedErrorBorder: inputBorder(AppColors.danger, 1.8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textDark,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.tilePurple,
      elevation: 0,
    ),
  );
}