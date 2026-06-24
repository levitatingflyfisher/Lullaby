import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/active_timer_card.dart';
import 'package:lullaby/features/tracking/presentation/controllers/timer_controller.dart';

import 'visual_golden_helper.dart';

void main() {
  // Renders the dashboard's active-timer cards (a feeding + a sleep timer) on a
  // narrow 320dp screen across accessibility text scales. The card packs an
  // icon, a label/elapsed column, and a STOP button into one Row, so a large
  // text scale on a narrow screen is the worst case for overflow.
  testWidgets('active-timer cards golden across text scales', (tester) async {
    final feedingTimer = ActiveTimer(
      id: 't1',
      type: TimerType.feeding,
      startTime: DateTime(2025, 6, 15, 10, 0),
      label: 'Breast (left)',
      elapsed: const Duration(minutes: 5, seconds: 30),
    );
    final sleepTimer = ActiveTimer(
      id: 't2',
      type: TimerType.sleep,
      startTime: DateTime(2025, 6, 15, 22, 0),
      label: 'Night sleep',
      elapsed: const Duration(hours: 1, minutes: 12, seconds: 45),
    );

    await goldenAtSizes(
      tester,
      name: 'active_timer_card',
      sizes: const <String, Size>{'phone': Size(360, 800), 'narrow': Size(320, 800)},
      textScales: const <double>[1.0, 3.0],
      // The dashboard hosts these cards inside a ListView, so use one here too:
      // at text scale 3.0 two stacked cards are taller than the 800dp viewport,
      // which is by-design scrollable content — not a card layout bug. This
      // isolates the test to the card's own (horizontal) layout.
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ActiveTimerCard(timer: feedingTimer, onStop: () {}),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ActiveTimerCard(timer: sleepTimer, onStop: () {}),
              ),
            ],
          ),
        ),
      ),
    );
  });
}
