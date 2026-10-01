import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/app/theme/theme.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
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

/// At 320 dp and 3x text the Home title shortened to "Lull…" beside a
/// full-size Settings word (parked from the rollout). The bar now folds
/// by space like the rest of the fleet: the word stays while it fits
/// beside a whole title, and folds into the tooltip when it doesn't.
void main() {
  final baby = BabyEntity(
    id: 'b1',
    name: 'Nora',
    dateOfBirth: DateTime(2025, 11, 1),
    createdAt: DateTime(2025, 11, 1),
    modifiedAt: DateTime(2025, 11, 1),
  );
  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3), (320.0, 3.0)]) {
    testWidgets('Home title is whole at ${width.toInt()} dp x $scale',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(initialLocation: '/dashboard', routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
      ]);
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
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final bar = find.byType(AppBar);
      final title = find.descendant(of: bar, matching: find.text('Lullaby'));
      final para = tester.renderObject<RenderParagraph>(title);
      expect(para.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(para.size.width + 0.5),
          reason: 'the Lullaby title is cut');
      // Settings is always there by name: worded at everyday sizes.
      expect(find.descendant(of: bar, matching: find.byIcon(Icons.settings)),
          findsOneWidget);
      if (scale <= 1.3) {
        expect(find.descendant(of: bar, matching: find.text('Settings')),
            findsOneWidget);
      }
    });
  }
}
