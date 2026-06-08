import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tune_bridge/core/constants.dart';

class ThemeState {
  final ThemeMode mode;
  final bool useMaterial3;
  final Color primaryColor;
  ThemeState(this.mode, this.useMaterial3, this.primaryColor);
}

class ThemeCubit extends Cubit<ThemeState> {
  static const Color defaultAccent = Color(0xFF00FF41);

  ThemeCubit() : super(ThemeState(ThemeMode.dark, false, defaultAccent)) {
    _readSettings();
  }

  void _readSettings() {
    final box = Hive.box(AppConstants.settingsBox);
    final int? accentValue = box.get('accentColor');
    Color accentColor = defaultAccent;
    if (accentValue != null) {
      accentColor = Color(accentValue);
    }
    final bool? useM3 = box.get('useMaterial3');
    emit(ThemeState(state.mode, useM3 ?? false, accentColor));
  }

  void toggleTheme(bool isDark) {
    emit(ThemeState(isDark ? ThemeMode.dark : ThemeMode.light, state.useMaterial3, state.primaryColor));
  }

  void toggleMaterial3(bool useM3) {
    final box = Hive.box(AppConstants.settingsBox);
    box.put('useMaterial3', useM3);
    emit(ThemeState(state.mode, useM3, state.primaryColor));
  }

  void setAccentColor(Color color) {
    final box = Hive.box(AppConstants.settingsBox);
    box.put('accentColor', color.toARGB32());
    emit(ThemeState(state.mode, state.useMaterial3, color));
  }
}
