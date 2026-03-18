import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

/// Neumorphic light-themed music app design system.
class AppTheme {
  AppTheme._();

  static const Color primary = GlassColors.accent;
  static const Color surface = GlassColors.surface;
  static const Color surfaceVariant = GlassColors.surfaceRaised;
  static const Color textPrimary = GlassColors.textPrimary;
  static const Color textSecondary = GlassColors.textSecondary;
  static const Color error = Color(0xFFFF5B5B);

  static ThemeData _obsidianTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: GlassColors.background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF67F0DA),
        surface: surface,
        error: error,
        onPrimary: Color(0xFF03130F),
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontSize: 30, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: const Color(0x1FFFFFFF),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: textSecondary.withValues(alpha: 0.2),
        thumbColor: primary,
        trackHeight: 4,
        overlayColor: primary.withValues(alpha: 0.14),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GlassColors.surfaceRaised,
        contentTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return _obsidianTheme();
  }

  static ThemeData get darkTheme {
    return _obsidianTheme();
  }
}
