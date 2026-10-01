import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/features/tracking/presentation/controllers/diaper_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/feeding_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/sleep_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/timer_controller.dart';

class _NoTimers extends ActiveTimersNotifier {
  @override
  List<ActiveTimer> build() => const [];
}

class _FakeSleepController extends SleepController {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  @override
  Future<Duration> getTodaySleepDuration(String babyId) async => Duration.zero;
}

class _FakeDiaperController extends DiaperController {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  @override
  Future<int> getTodayDiaperCount(String babyId) async => 0;
  @override
  Future<DiaperLogEntity?> quickLogWet() async => DiaperLogEntity(
        id: 'd1',
        babyId: 'b1',
        time: DateTime(2026, 9, 1),
        type: DiaperType.wet,
        createdAt: DateTime(2026, 9, 1),
        modifiedAt: DateTime(2026, 9, 1),
      );
}

/// The "Wet diaper logged / EDIT" snackbar stayed up for minutes, across
/// screens (sync-B concern 7): a SnackBar with an action persists until
/// tapped unless told otherwise. The diaper is already saved; EDIT is a
/// convenience, so the line goes away on its own like the others.
void main() {
  testWidgets('the quick-log diaper line dismisses itself', (tester) async {
    final baby = BabyEntity(
      id: 'b1',
      name: 'Nora',
      dateOfBirth: DateTime(2025, 11, 1),
      createdAt: DateTime(2025, 11, 1),
      modifiedAt: DateTime(2025, 11, 1),
    );
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
        GoRoute(
            path: '/diaper',
            builder: (_, _) => const Scaffold(body: Text('diaper form'))),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
        allEventsProvider.overrideWith(
            (ref, babyId) => Stream.value(const <TimelineEvent>[])),
        lastFeedingProvider.overrideWith((ref, babyId) => Stream.value(null)),
        activeTimersProvider.overrideWith(() => _NoTimers()),
        sleepControllerProvider.overrideWith(() => _FakeSleepController()),
        diaperControllerProvider.overrideWith(() => _FakeDiaperController()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diaper'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Wet diaper logged'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'EDIT'), findsOneWidget);

    // Well past the default 4 s display time.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Wet diaper logged'), findsNothing);
  });
}
