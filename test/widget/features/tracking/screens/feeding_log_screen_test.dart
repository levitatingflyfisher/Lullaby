import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/app/theme/theme.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/presentation/controllers/feeding_controller.dart';
import 'package:lullaby/features/tracking/presentation/screens/feeding_log_screen.dart';

class _FakeFeedingController extends FeedingController {
  final notesSaves = <(String, String?)>[];

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<FeedingLogEntity?> startBreastFeeding(BreastSide side,
          {String? notes}) async =>
      FeedingLogEntity(
        id: 'live',
        babyId: 'baby1',
        type: FeedingType.breast,
        startTime: DateTime(2025, 6, 15, 10, 0),
        side: side,
        notes: notes,
        createdAt: DateTime(2025, 6, 15),
        modifiedAt: DateTime(2025, 6, 15),
      );

  @override
  Future<Result<void>> saveFeedNotes(String logId, String notes) async {
    notesSaves.add((logId, notes));
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteLog(String id) async => const Success(null);
}

void main() {
  final fakeFeedingLog = FeedingLogEntity(
    id: 'f1',
    babyId: 'baby1',
    type: FeedingType.breast,
    startTime: DateTime(2025, 6, 15, 10, 0),
    side: BreastSide.left,
    createdAt: DateTime(2025, 6, 15),
    modifiedAt: DateTime(2025, 6, 15),
  );

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
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Widget buildEditMode() {
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, _) => Scaffold(
            body: TextButton(
              onPressed: () => router.push('/feeding', extra: fakeFeedingLog),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/feeding',
          builder: (ctx, _) => const FeedingLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        feedingControllerProvider.overrideWith(() => _FakeFeedingController()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Widget buildCreateWithExtra(Object extra) {
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, _) => Scaffold(
            body: TextButton(
              onPressed: () => router.push('/feeding', extra: extra),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/feeding',
          builder: (ctx, _) => const FeedingLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        feedingControllerProvider.overrideWith(() => _FakeFeedingController()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Set<FeedingType> selectedType(WidgetTester tester) => tester
      .widget<SegmentedButton<FeedingType>>(
          find.byType(SegmentedButton<FeedingType>))
      .selected;

  // lullaby:doet-01 — the Feed sheet's answer used to be dropped and the form
  // always opened on Breast.
  group('FeedingLogScreen seeded with a FeedingType', () {
    for (final type in FeedingType.values) {
      testWidgets('opens create mode on ${type.name}', (tester) async {
        await tester.pumpWidget(buildCreateWithExtra(type));
        await tester.pump();
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(find.text('Log Feeding'), findsOneWidget);
        expect(selectedType(tester), {type});
      });
    }
  });

  // lullaby:doet-02 — bottle Save with an empty amount did nothing at all.
  group('FeedingLogScreen bottle Save', () {
    FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'));

    testWidgets('is disabled until a positive amount is entered',
        (tester) async {
      await tester.pumpWidget(buildCreateWithExtra(FeedingType.bottle));
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(
          find.widgetWithText(TextField, 'Amount (ml)'), '0');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(
          find.widgetWithText(TextField, 'Amount (ml)'), '120');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNotNull);
    });
  });

  // Concern from item 34: a note typed AFTER Start was lost when the feed
  // was stopped from the Home timer card, which passes no notes. The form
  // now saves notes onto the open feed as they are typed.
  testWidgets('notes typed after Start are saved onto the open feed',
      (tester) async {
    final fake = _FakeFeedingController();
    await tester.pumpWidget(ProviderScope(
      overrides: [feedingControllerProvider.overrideWith(() => fake)],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/feeding',
          routes: [
            GoRoute(
                path: '/feeding',
                builder: (ctx, _) => const FeedingLogScreen()),
          ],
        ),
      ),
    ));
    await tester.pump();

    // Nothing is open yet: typing before Start saves nothing on its own.
    await tester.enterText(
        find.widgetWithText(TextField, 'Notes (optional)'), 'before');
    await tester.pump();
    expect(fake.notesSaves, isEmpty);

    await tester.tap(find.text('Start'));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextField, 'Notes (optional)'), 'left side, 10 min');
    await tester.pump();
    expect(fake.notesSaves.last, ('live', 'left side, 10 min'));
  });

  group('FeedingLogScreen', () {
    testWidgets('create mode shows "Log Feeding" title', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.text('Log Feeding'), findsOneWidget);
    });

    testWidgets('create mode has no delete button', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('edit mode shows "Edit Feeding" title', (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Feeding'), findsOneWidget);
    });

    testWidgets('edit mode shows delete icon in AppBar', (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  // Ruling: below 360dp the feed-type selector drops its check mark so
  // "Breast" stays whole in the fleet's wider Nunito; the fill still shows
  // which one is chosen. At 360dp and up the check stays.
  for (final (width, showsCheck) in const [(320.0, false), (360.0, true)]) {
    testWidgets('feed type at ${width.toInt()}dp: check $showsCheck, '
        '"Breast" on one line', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const FeedingLogScreen()),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          feedingControllerProvider
              .overrideWith(() => _FakeFeedingController()),
        ],
        child: MaterialApp.router(
            theme: AppTheme.light(), routerConfig: router),
      ));
      await tester.pumpAndSettle();

      final selector = tester.widget<SegmentedButton<FeedingType>>(
          find.byType(SegmentedButton<FeedingType>));
      expect(selector.showSelectedIcon, showsCheck);
      final breast = tester.renderObject<RenderParagraph>(find.text('Breast'));
      expect(
          breast.size.height,
          lessThanOrEqualTo(
              breast.getMinIntrinsicHeight(double.infinity) + 0.5),
          reason: '"Breast" wrapped');
    });
  }
}
