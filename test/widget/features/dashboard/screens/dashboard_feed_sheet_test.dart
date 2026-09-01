import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
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
}

/// lullaby:doet-01 — the Feed circle's Breast/Bottle/Solid sheet pushed
/// /feeding with nothing, so the parent answered and was asked again.
void main() {
  final baby = BabyEntity(
    id: 'b1',
    name: 'Nora',
    dateOfBirth: DateTime(2025, 11, 1),
    createdAt: DateTime(2025, 11, 1),
    modifiedAt: DateTime(2025, 11, 1),
  );

  for (final (label, type) in const [
    ('Breast', FeedingType.breast),
    ('Bottle', FeedingType.bottle),
    ('Solid', FeedingType.solid),
  ]) {
    testWidgets('sheet "$label" pushes /feeding with ${type.name}',
        (tester) async {
      Object? pushedExtra;
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/feeding',
            builder: (_, state) {
              pushedExtra = state.extra;
              return const Scaffold(body: Text('feeding form'));
            },
          ),
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

      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.text('feeding form'), findsOneWidget);
      expect(pushedExtra, type);
    });
  }
}
