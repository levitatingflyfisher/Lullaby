import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/diaper_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/feeding_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/sleep_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/timer_controller.dart';

import 'visual_golden_helper.dart';

// Fake timers notifier: returns a fixed list and never watches activeBaby or
// reads repositories (the real build() does), so the dashboard renders one
// feeding-timer card deterministically without a DB.
class _FakeActiveTimers extends ActiveTimersNotifier {
  _FakeActiveTimers(this._timers);
  final List<ActiveTimer> _timers;
  @override
  List<ActiveTimer> build() => _timers;
}

// Fake sleep/diaper controllers: the dashboard's _DailySummary FutureBuilder
// calls getTodaySleepDuration / getTodayDiaperCount on these notifiers, which
// normally hit Drift. Return fixed values so the summary chips render real
// numbers instead of the '...' placeholder.
class _FakeSleepController extends SleepController {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  @override
  Future<Duration> getTodaySleepDuration(String babyId) async =>
      const Duration(hours: 4, minutes: 20);
}

class _FakeDiaperController extends DiaperController {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  @override
  Future<int> getTodayDiaperCount(String babyId) async => 6;
}

void main() {
  final fakeBaby = BabyEntity(
    id: 'baby1',
    name: 'Alice',
    dateOfBirth: DateTime(2024, 12, 1),
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  final activeTimer = ActiveTimer(
    id: 't1',
    type: TimerType.feeding,
    startTime: DateTime(2025, 6, 15, 10, 0),
    label: 'Breast (left)',
    elapsed: const Duration(minutes: 5, seconds: 30),
  );

  // Renders the populated dashboard (appbar with baby name, one active-timer
  // card, the Feed/Sleep/Diaper quick-log row, and the daily-summary strip)
  // with all data mocked via ProviderScope. Swept at phone + narrow widths
  // across text scales 1.0 and 3.0 — the worst case for the quick-log row and
  // summary chips overflowing on small/large-font screens.
  testWidgets('DashboardScreen responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'dashboard_screen',
      sizes: const <String, Size>{'phone': Size(360, 800), 'narrow': Size(320, 800)},
      textScales: const <double>[1.0, 3.0],
      home: ProviderScope(
        overrides: [
          activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
          allEventsProvider.overrideWith(
              (ref, babyId) => Stream.value(const <TimelineEvent>[])),
          lastFeedingProvider.overrideWith((ref, babyId) => Stream.value(null)),
          activeTimersProvider
              .overrideWith(() => _FakeActiveTimers(<ActiveTimer>[activeTimer])),
          sleepControllerProvider.overrideWith(() => _FakeSleepController()),
          diaperControllerProvider.overrideWith(() => _FakeDiaperController()),
        ],
        child: const DashboardScreen(),
      ),
    );
  });
}
