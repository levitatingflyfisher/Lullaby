import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/daily_summary_strip.dart';

import 'visual_golden_helper.dart';

void main() {
  testWidgets('DailySummaryStrip responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'daily_summary_strip',
      home: const Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: DailySummaryStrip(
              lastFeedTime: '2h ago',
              sleepDuration: '4h 20m',
              diaperCount: 6,
            ),
          ),
        ),
      ),
    );
  });
}
