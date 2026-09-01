import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/theme/theme.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// Operator ruling: one type system across the fleet. Lullaby's light and
/// dark themes (including the dynamic-colour ones) carry ohStyle's
/// Material text theme: package Lora for display and headline, package
/// Nunito for everything else, on the fleet's type ladder.
void main() {
  const lora = 'packages/openhearth_design/Lora';
  const nunito = 'packages/openhearth_design/Nunito';

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
    ('light dynamic',
        AppTheme.light(ColorScheme.fromSeed(seedColor: Colors.teal))),
  ]) {
    test('$name theme uses the fleet type', () {
      final t = theme.textTheme;
      expect(t.headlineSmall?.fontFamily, lora);
      expect(t.displayLarge?.fontFamily, lora);
      expect(t.titleLarge?.fontFamily, nunito);
      expect(t.bodyMedium?.fontFamily, nunito);
      expect(t.labelLarge?.fontFamily, nunito);
      for (final (slot, style) in [
        ('bodyMedium', t.bodyMedium),
        ('titleLarge', t.titleLarge),
        ('labelSmall', t.labelSmall),
      ]) {
        final expected = switch (slot) {
          'bodyMedium' => OhTypography.materialTextTheme.bodyMedium,
          'titleLarge' => OhTypography.materialTextTheme.titleLarge,
          _ => OhTypography.materialTextTheme.labelSmall,
        };
        expect(style?.fontSize, expected?.fontSize, reason: slot);
        expect(style?.fontWeight, expected?.fontWeight, reason: slot);
      }
      // Colours still come from the scheme (ThemeData merges them in).
      expect(t.bodyMedium?.color, isNotNull);
    });
  }
}
