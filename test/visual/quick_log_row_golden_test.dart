import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'quick_log_row_fixture.dart';
import 'visual_golden_helper.dart';

void main() {
  // Renders the dashboard's quick-log row on a narrow (320dp) screen across
  // accessibility text scales, so the goldens show the labels stay inside their
  // buttons and the row never overflows.
  testWidgets('quick-log row golden across text scales', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'quick_log_row',
      sizes: const <String, Size>{'narrow': Size(320, 400)},
      textScales: const <double>[1.0, 2.0, 3.0],
      home: Scaffold(body: buildQuickLogRow()),
    );
  });
}
