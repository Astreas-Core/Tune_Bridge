import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

/// Neumorphic light-themed music app design system.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF2AE6C9);
  static const Color surface = Color(0xFF0C0C0E);
  static const Color surfaceVariant = Color(0xFF141419);
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFF9A9AA3);
  static const Color error = Color(0xFFFF5B5B);

  static ThemeData _obsidianTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: Color(0xFF050505),
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
      dividerColor: Color(0x1FFFFFFF),
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
        backgroundColor: Color(0xFF141419),
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

  static ThemeData material3Theme(Color seedColor) {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}

extension BuildContextThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get surfaceColor => colorScheme.surface;
  Color get surfaceRaisedColor => colorScheme.surfaceContainerHigh;
  Color get primaryColor => colorScheme.primary;
  Color get textPrimaryColor => colorScheme.onSurface;
  Color get textSecondaryColor => colorScheme.onSurfaceVariant;
}
