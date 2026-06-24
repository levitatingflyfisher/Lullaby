import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../visual/quick_log_row_fixture.dart';

void main() {
  // Wraps the shared quick-log row in a MediaQuery with an exaggerated text
  // scale, on a phone-width surface, to exercise how the dashboard's buttons
  // behave under large accessibility fonts.
  Widget harness({required double textScale}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: buildQuickLogRow()),
        ),
      ),
    );
  }

  testWidgets(
      'quick-log row does not overflow at max accessibility text scale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness(textScale: 3.0));

    // No RenderFlex overflow on a narrow screen (≤320dp: foldable cover, small
    // phones) even at max accessibility text scale.
    expect(tester.takeException(), isNull);
  });
}
