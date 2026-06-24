import 'package:flutter/material.dart';

abstract final class AppColorSchemes {
  static const Color seedColor = Color(0xFF7B8FD4);

  static ColorScheme lightFallback = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  static ColorScheme darkFallback = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );

  // Semantic colors for quick-log buttons
  static const Color feedColor = Color(0xFF4CAF50);
  static const Color sleepColor = Color(0xFF5C6BC0);
  static const Color diaperColor = Color(0xFFFFA726);
}
