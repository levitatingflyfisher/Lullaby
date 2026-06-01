import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/quick_log_button.dart';

import 'visual_golden_helper.dart';

void main() {
  // Renders a single QuickLogButton in isolation across accessibility text
  // scales at a narrow width. The label is bounded to the button's circle
  // width (maxLines: 2, ellipsis), so this golden confirms a long label wraps
  // to two lines and truncates rather than widening the column.
  testWidgets('quick-log button golden across text scales', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'quick_log_button',
      sizes: const <String, Size>{'narrow': Size(320, 400)},
      textScales: const <double>[1.0, 3.0],
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: QuickLogButton(
              icon: Icons.baby_changing_station,
              label: 'Diaper',
              color: Colors.amber,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  });
}
