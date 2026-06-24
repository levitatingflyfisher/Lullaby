import 'package:flutter/material.dart';

abstract final class AppComponentThemes {
  static CardThemeData cardTheme(ColorScheme colorScheme) => CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );

  static FloatingActionButtonThemeData fabTheme(ColorScheme colorScheme) =>
      FloatingActionButtonThemeData(
        shape: const CircleBorder(),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      );

  static SegmentedButtonThemeData segmentedButtonTheme(
          ColorScheme colorScheme) =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  static BottomNavigationBarThemeData bottomNavTheme(
          ColorScheme colorScheme) =>
      BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      );

  static FilledButtonThemeData filledButtonTheme(ColorScheme colorScheme) =>
      FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
