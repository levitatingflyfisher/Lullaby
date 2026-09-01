import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/daily_summary_strip.dart';

void main() {
  // lullaby:dmmt-07 — the strip scrolled horizontally, so "Diapers" was off
  // screen at 360 dp and "Sleep" too at text scale 1.3. A finder finds
  // off-screen text, so check geometry: every chip must sit inside the width.
  group('DailySummaryStrip geometry', () {
    // At 2.0 a Chip sheared "Last feed: 2 hours ago" (a Chip fixes its
    // height to one line). The pill wraps its label onto a second line
    // instead, so every label is read in full at every width and scale.
    for (final (width, scale) in const [
      (360.0, 1.0),
      (360.0, 1.3),
      (360.0, 2.0),
      (320.0, 2.0),
      (320.0, 3.0),
    ]) {
      testWidgets('all three labels whole at ${width.toInt()} dp x $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(scale),
            ),
            child: const Scaffold(
              body: DailySummaryStrip(
                lastFeedTime: '2 hours ago',
                sleepDuration: '11h 45m',
                diaperCount: 12,
              ),
            ),
          ),
        ));

        expect(tester.takeException(), isNull);
        for (final label in const [
          'Last feed: 2 hours ago',
          'Sleep: 11h 45m',
          'Diapers: 12',
        ]) {
          final pill = tester.getRect(find.ancestor(
              of: find.text(label), matching: find.byType(DailySummaryPill)));
          final text = tester.getRect(find.text(label));
          expect(pill.left, greaterThanOrEqualTo(0), reason: label);
          expect(pill.right, lessThanOrEqualTo(width), reason: label);
          expect(text.left, greaterThanOrEqualTo(pill.left), reason: label);
          expect(text.right, lessThanOrEqualTo(pill.right), reason: label);
          expect(text.bottom, lessThanOrEqualTo(pill.bottom), reason: label);
          // Nothing may be cut off: every line of the label is laid out.
          final paragraph =
              tester.renderObject<RenderParagraph>(find.text(label));
          expect(paragraph.didExceedMaxLines, isFalse,
              reason: '$label is cut off');
          // A one-line label narrower than its text is sheared (what the
          // Chip did); a label that may wrap is fine if every line fits.
          final oneLineFits =
              paragraph.getMaxIntrinsicWidth(double.infinity) <=
                  paragraph.size.width + 0.5;
          expect(oneLineFits || paragraph.softWrap, isTrue,
              reason: '$label is sheared on one line');
          expect(paragraph.size.height,
              greaterThanOrEqualTo(paragraph.getMaxIntrinsicHeight(
                      paragraph.size.width) -
                  0.5),
              reason: '$label is clipped');
        }
      });
    }
  });

  group('DailySummaryStrip', () {
    testWidgets('renders all three chips', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DailySummaryStrip(
            lastFeedTime: '2h ago',
            sleepDuration: '4h 20m',
            diaperCount: 6,
          ),
        ),
      ));

      expect(find.text('Last feed: 2h ago'), findsOneWidget);
      expect(find.text('Sleep: 4h 20m'), findsOneWidget);
      expect(find.text('Diapers: 6'), findsOneWidget);
    });

    testWidgets('shows correct icons', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DailySummaryStrip(
            lastFeedTime: '1h ago',
            sleepDuration: '2h 0m',
            diaperCount: 3,
          ),
        ),
      ));

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.bedtime), findsOneWidget);
      expect(find.byIcon(Icons.baby_changing_station), findsOneWidget);
    });
  });
}
