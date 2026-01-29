import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark fintech-inspired palette with medical contrast
  static const background = Color(0xFF0B0B0F); // deep charcoal
  static const surface = Color(0xFF14161E); // card surface
  static const overlay = Color(0x1AFFFFFF); // glass overlay

  // Accents (primary = red, secondary = teal for success/quality)
  static const primary = Color(0xFFFF4C4C); // vivid red for primary actions
  static const secondary = Color(0xFF10B981); // teal for good states
  static const warning = Color(0xFFF59E0B); // amber for caution
  static const danger = Color(0xFFE11D48); // deeper red for errors

  // Text
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF9CA3AF);

  // Risk colors
  static const Map<String, Color> riskColors = {
    'NORMAL': Colors.green,
    'RENDAH': Colors.green,
    'MILD': Colors.orange,
    'SEDANG': Colors.orange,
    'MODERATE': Colors.orange,
    'TINGGI': Colors.red,
    'SEVERE': Colors.red,
    'IMMATURE': Colors.orange,
    'MATURE': Colors.red,
    'TIDAK DIKETAHUI': Colors.grey,
    'UNKNOWN': Colors.grey,
    'ERROR': danger,
  };
}

class AppText {
  static TextStyle get title => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headline => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 15,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        color: AppColors.textSecondary,
      );
}

class AppDecor {
  static BoxDecoration circleFrame({double borderAlpha = 0.55}) =>
      BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: borderAlpha),
          width: 2.4,
        ),
      );

  static BoxDecoration card({double borderAlpha = 0.12}) => BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
      );
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
