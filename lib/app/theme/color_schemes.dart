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

  // The category palette: one colour per kind of record, used by the
  // quick-log circles, the summary strip, the timer card, activity rows,
  // calendar dots and the charts. Change a colour here, nowhere else
  // (category_palette_test fails on a hex literal outside lib/app/theme/).
  // Every category also differs by icon, so colour is never the only cue.
  static const Color feedColor = Color(0xFF4CAF50);
  static const Color sleepColor = Color(0xFF5C6BC0);
  static const Color diaperColor = Color(0xFFFFA726);
  static const Color growthColor = Color(0xFF26A69A);
  static const Color medicineColor = Color(0xFF7E57C2);
  static const Color vaccineColor = Color(0xFF42A5F5);

  // Diaper chart series: wet, dirty; "both" uses [diaperColor].
  static const Color diaperWetColor = Color(0xFF42A5F5);
  static const Color diaperDirtyColor = Color(0xFF8D6E63);
}
