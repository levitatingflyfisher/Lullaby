import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'components.dart';

abstract final class AppTheme {
  static ThemeData light([ColorScheme? dynamicScheme]) {
    final colorScheme = dynamicScheme ?? AppColorSchemes.lightFallback;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: AppComponentThemes.cardTheme(colorScheme),
      floatingActionButtonTheme: AppComponentThemes.fabTheme(colorScheme),
      segmentedButtonTheme:
          AppComponentThemes.segmentedButtonTheme(colorScheme),
      bottomNavigationBarTheme: AppComponentThemes.bottomNavTheme(colorScheme),
      filledButtonTheme: AppComponentThemes.filledButtonTheme(colorScheme),
    );
  }

  static ThemeData dark([ColorScheme? dynamicScheme]) {
    final colorScheme = dynamicScheme ?? AppColorSchemes.darkFallback;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: AppComponentThemes.cardTheme(colorScheme),
      floatingActionButtonTheme: AppComponentThemes.fabTheme(colorScheme),
      segmentedButtonTheme:
          AppComponentThemes.segmentedButtonTheme(colorScheme),
      bottomNavigationBarTheme: AppComponentThemes.bottomNavTheme(colorScheme),
      filledButtonTheme: AppComponentThemes.filledButtonTheme(colorScheme),
    );
  }
}
