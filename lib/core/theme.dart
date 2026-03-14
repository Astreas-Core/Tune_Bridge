import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/neumorphic.dart';

/// Neumorphic light-themed music app design system.
class AppTheme {
  AppTheme._();

  // Brand colours — Stitch palette
  static const Color primary = Color(0xFFD9E8A1); // Stitch Primary Lime
  static const Color surface = Color(0xFFF7F8F6); // Stitch Light
  static const Color surfaceVariant = Color(0xFFE2E8F0); // Slate-200
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color error = Color(0xFFEF4444); // Red-500

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: Neumorphic.background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFF64748B),
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.splineSansTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontSize: 30, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Neumorphic.shadowDark.withValues(alpha: 0.3),
        thumbColor: primary,
        trackHeight: 4,
        overlayColor: primary.withValues(alpha: 0.15),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }

  static ThemeData get darkTheme {
    // Hardcoded dark theme values to align with Neumorphic Dark Palette
    const darkSurface = Color(0xFF2E3239);
    const darkTextPrim = Color(0xFFE0E0E0);
    const darkTextSec = Color(0xFFAAAAAA);
    const darkCard = Color(0xFF2E3239);

    return ThemeData(
      brightness: Brightness.dark, // Important for status bar/adaptive widgets
      primaryColor: primary,
      scaffoldBackgroundColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: darkSurface,
        error: error,
        onPrimary: Colors.white,
        onSurface: darkTextPrim,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(color: darkTextPrim, fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: darkTextPrim, fontSize: 22, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: darkTextPrim, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: darkTextPrim, fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: darkTextPrim, fontSize: 16),
          bodyMedium: TextStyle(color: darkTextSec, fontSize: 14),
          bodySmall: TextStyle(color: darkTextSec, fontSize: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: darkTextPrim, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        iconTheme: IconThemeData(color: darkTextPrim),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: darkTextSec,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Colors.black26,
        thumbColor: primary,
        trackHeight: 4,
        overlayColor: primary.withValues(alpha: 0.15),
      ),
      iconTheme: const IconThemeData(color: darkTextPrim),
    );
  }
}
