import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/app_colors.dart';
import '../core/design_system/app_text.dart';

ThemeData buildTunelyTheme(AppColors colors) {
  final text = AppText.from(colors);
  return ThemeData(
    useMaterial3: true,
    brightness: colors.brightness,
    scaffoldBackgroundColor: colors.bg,
    fontFamily: AppText.family,
    splashFactory: NoSplash.splashFactory,
    colorScheme: ColorScheme(
      brightness: colors.brightness,
      primary: colors.accent,
      onPrimary: colors.accentText,
      secondary: colors.accent,
      onSecondary: colors.accentText,
      error: colors.danger,
      onError: colors.accentText,
      surface: colors.surface,
      onSurface: colors.text,
    ),
    extensions: [colors, text],
  );
}

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
