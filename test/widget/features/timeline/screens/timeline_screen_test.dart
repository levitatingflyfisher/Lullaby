import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/controllers/growth_controller.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/stats/presentation/controllers/stats_controller.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
import 'package:lullaby/features/timeline/presentation/screens/timeline_screen.dart';

void main() {
  final fakeBaby = BabyEntity(
    id: 'baby1',
    name: 'Alice',
    dateOfBirth: DateTime(2024, 12, 1),
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  Widget buildSubject({BabyEntity? baby}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
        dailySummariesProvider.overrideWith((ref, babyId) async => []),
        growthRecordsProvider.overrideWith(
            (ref, babyId) => Stream.value(<GrowthRecordEntity>[])),
        timelineProvider.overrideWith(
            (ref, babyId) => Stream.value([])),
      ],
      child: const MaterialApp(home: TimelineScreen()),
    );
  }

  group('TimelineScreen', () {
    testWidgets('shows "Timeline" in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Timeline'), findsOneWidget);
    });

    testWidgets('shows Charts and Events tabs', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Charts'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('default tab is Charts', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      // PeriodSelector is only in ChartsTab
      expect(find.text('7d'), findsOneWidget);
    });

    testWidgets('tapping Events tab shows filter chips', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      // TimelineFilterChips renders "All" chip
      expect(find.text('All'), findsOneWidget);
    });

    // At 320dp and text scale 3.0 the Calendar action beside the title cut
    // "Timeline" to "Time…". The title keeps the bar to itself now.
    testWidgets('title is whole at 320dp and text scale 3.0', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(3.0),
        ),
        child: buildSubject(baby: fakeBaby),
      ));
      await tester.pump();

      final title = tester.renderObject<RenderParagraph>(find.descendant(
          of: find.byType(AppBar), matching: find.text('Timeline')));
      expect(title.didExceedMaxLines, isFalse, reason: 'title is truncated');
    });

    testWidgets('Events offers the Calendar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsOneWidget);
    });

    // At 3.0 the fixed 46dp tab bar cropped "Charts" and "Events" top and
    // bottom; the tabs grow with the text now.
    testWidgets('tab labels are whole at 320dp and text scale 3.0',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(3.0),
        ),
        child: buildSubject(baby: fakeBaby),
      ));
      await tester.pump();

      final bar = tester.getRect(find.byType(TabBar));
      for (final label in ['Charts', 'Events']) {
        final text = tester.getRect(find.text(label));
        final tab = tester.getRect(find.ancestor(
            of: find.text(label), matching: find.byType(Tab)));
        expect(text.top, greaterThanOrEqualTo(tab.top), reason: label);
        expect(text.bottom, lessThanOrEqualTo(tab.bottom), reason: label);
        expect(tab.bottom, lessThanOrEqualTo(bar.bottom), reason: label);
        // The label's box can be squeezed to the tab's height while its
        // glyphs spill out and are clipped; require the full line height.
        final p = tester.renderObject<RenderParagraph>(find.text(label));
        expect(p.size.height,
            greaterThanOrEqualTo(p.getMinIntrinsicHeight(p.size.width) - 0.5),
            reason: '$label is cropped');
      }
    });
  });
}
