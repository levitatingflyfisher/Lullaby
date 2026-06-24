import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/tracking/presentation/controllers/feeding_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/timer_controller.dart';
import 'package:lullaby/features/tracking/presentation/screens/feeding_log_screen.dart';

import 'visual_golden_helper.dart';

// Mirrors the create-mode setup in
// test/widget/features/tracking/screens/feeding_log_screen_test.dart: a fake
// feeding controller (no DB) plus a GoRouter, which the screen needs because
// didChangeDependencies reads GoRouterState.of(context).extra.
class _FakeFeedingController extends FeedingController {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  @override
  Future<Result<void>> deleteLog(String id) async => const Success(null);
}

// Fake timers notifier so the create-mode build() (which watches
// activeTimersProvider) doesn't trigger the real notifier's repository reads.
class _FakeActiveTimers extends ActiveTimersNotifier {
  @override
  List<ActiveTimer> build() => const <ActiveTimer>[];
}

void main() {
  Widget buildCreateMode() {
    final router = GoRouter(
      initialLocation: '/feeding',
      routes: [
        GoRoute(
          path: '/feeding',
          builder: (ctx, _) => const FeedingLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        feedingControllerProvider.overrideWith(() => _FakeFeedingController()),
        activeTimersProvider.overrideWith(() => _FakeActiveTimers()),
      ],
      // The inner MaterialApp.router provides the GoRouter the screen needs;
      // the helper's outer MaterialApp supplies the MediaQuery text scale.
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }

  // Renders the feeding-log create screen (Breast selected by default: the
  // Breast/Bottle/Solid SegmentedButton, the L/R/Both side toggle, the Start
  // button, and the notes field) across phone + narrow widths and text scales
  // 1.0 / 3.0. The SegmentedButton's three labels in a row are the overflow
  // risk on a 320dp screen at large font scale.
  testWidgets('FeedingLogScreen create-mode responsive golden sweep',
      (tester) async {
    await goldenAtSizes(
      tester,
      name: 'feeding_log_screen',
      sizes: const <String, Size>{'phone': Size(360, 800), 'narrow': Size(320, 800)},
      textScales: const <double>[1.0, 3.0],
      home: buildCreateMode(),
    );
  });
}
