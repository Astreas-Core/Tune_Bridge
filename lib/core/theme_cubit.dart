import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/neumorphic.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark) {
    _readAccentOnly();
    _syncDesignSystem(true);
  }

  static void _readAccentOnly() {
    final box = Hive.box(AppConstants.settingsBox);
    final int? accentValue = box.get('accentColor');
    if (accentValue != null) {
      Neumorphic.setAccent(Color(accentValue));
    }
  }

  void _syncDesignSystem(bool isDark) {
    Neumorphic.setIsDark(isDark);
  }

  void toggleTheme(bool isDark) {
    // Dark mode is fixed for TuneBridge; keep API for compatibility.
    _syncDesignSystem(true);
    emit(ThemeMode.dark);
  }

  void setAccentColor(Color color) {
    final box = Hive.box(AppConstants.settingsBox);
    // Use toARGB32() instead of .value which is deprecated
    // Assuming Hive handles int storage fine.
    // If toARGB32 is not available (older flutter), we might need another way, 
    // but the linter suggested it so it should be there.
    // However, to keep it simple and safe if the method creates a new int, let's use it.
    // Wait, Color(int) constructor expects ARGB int. toARGB32() returns that.
    box.put('accentColor', color.toARGB32());
    Neumorphic.setAccent(color);
    // Emit new state to force rebuild if possible, but ThemeMode doesn't change color.
    // However, since Neumorphic.accent is static, widgets using it will update on rebuild.
    // We can re-emit the current state to trigger BlocBuilder (if it checks identity).
    // But since state is primitive enum, it might not trigger.
    // But we are asking for restart anyway.
  }
}
