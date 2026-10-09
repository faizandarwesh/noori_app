import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_sizes.dart';
export 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData day() => _build(NooriColors.day, Brightness.light);
  static ThemeData bedtime() => _build(NooriColors.bedtime, Brightness.dark);

  static ThemeData _build(NooriColors c, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppFonts.english,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
        surface: c.surface,
        primary: c.primary,
        secondary: c.secondary,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: [c],
    );
  }
}

extension NooriThemeContext on BuildContext {
  NooriColors get colors =>
      Theme.of(this).extension<NooriColors>() ?? NooriColors.day;
}
