import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import 'color_schemes.dart';
import 'components.dart';

abstract final class AppTheme {
  // The fleet's one type system (operator ruling): package Lora for display
  // and headline, package Nunito for the rest, on ohStyle's type ladder.
  // Colours still come from each scheme; ThemeData merges them in.
  static const TextTheme _textTheme = OhTypography.materialTextTheme;

  static ThemeData light([ColorScheme? dynamicScheme]) {
    final colorScheme = dynamicScheme ?? AppColorSchemes.lightFallback;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
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
      textTheme: _textTheme,
      cardTheme: AppComponentThemes.cardTheme(colorScheme),
      floatingActionButtonTheme: AppComponentThemes.fabTheme(colorScheme),
      segmentedButtonTheme:
          AppComponentThemes.segmentedButtonTheme(colorScheme),
      bottomNavigationBarTheme: AppComponentThemes.bottomNavTheme(colorScheme),
      filledButtonTheme: AppComponentThemes.filledButtonTheme(colorScheme),
    );
  }
}
