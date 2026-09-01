import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/theme/color_schemes.dart';

/// lullaby:dfh-02 — the category colours (feed, sleep, diaper, growth,
/// medicine, vaccine) were retyped as hex literals in several widgets, and
/// the sleep chart had drifted to its own indigo. They live in one table
/// now, and a hex literal anywhere else in lib/ fails here.
void main() {
  test('no colour hex literal outside lib/app/theme/', () {
    final hex = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
      if (f.path.startsWith('lib/app/theme/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (hex.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });

  test('each category has its own colour', () {
    const categories = <Color>[
      AppColorSchemes.feedColor,
      AppColorSchemes.sleepColor,
      AppColorSchemes.diaperColor,
      AppColorSchemes.growthColor,
      AppColorSchemes.medicineColor,
      AppColorSchemes.vaccineColor,
    ];
    expect(categories.toSet(), hasLength(categories.length));
  });
}
