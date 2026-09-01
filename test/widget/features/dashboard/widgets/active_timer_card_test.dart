import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/theme/theme.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/active_timer_card.dart';
import 'package:lullaby/features/tracking/presentation/controllers/timer_controller.dart';

void main() {
  group('ActiveTimerCard', () {
    final timer = ActiveTimer(
      id: 't1',
      type: TimerType.feeding,
      startTime: DateTime(2025, 6, 15, 10, 0),
      label: 'Breast (left)',
      elapsed: const Duration(minutes: 5, seconds: 30),
    );

    testWidgets('renders label and elapsed time', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActiveTimerCard(
            timer: timer,
            onStop: () {},
          ),
        ),
      ));

      expect(find.text('Breast (left)'), findsOneWidget);
      expect(find.text('00:05:30'), findsOneWidget);
    });

    testWidgets('shows STOP button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActiveTimerCard(
            timer: timer,
            onStop: () {},
          ),
        ),
      ));

      expect(find.text('STOP'), findsOneWidget);
    });

    testWidgets('calls onStop when STOP pressed', (tester) async {
      var stopped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActiveTimerCard(
            timer: timer,
            onStop: () => stopped = true,
          ),
        ),
      ));

      await tester.tap(find.text('STOP'));
      expect(stopped, isTrue);
    });

    testWidgets('shows feeding icon for feeding timer', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActiveTimerCard(
            timer: timer,
            onStop: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('shows sleep icon for sleep timer', (tester) async {
      final sleepTimer = ActiveTimer(
        id: 't2',
        type: TimerType.sleep,
        startTime: DateTime(2025, 6, 15, 22, 0),
        label: 'Nap',
        elapsed: const Duration(hours: 1),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActiveTimerCard(
            timer: sleepTimer,
            onStop: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.bedtime), findsOneWidget);
    });

    // At 320dp and text scale 3.0 the label, the clock and STOP shared one
    // row, so "Breast (left)" and "00:05:30" broke one character per line.
    for (final (width, scale) in const [
      (360.0, 1.0),
      (320.0, 1.0),
      (360.0, 2.0),
      (320.0, 3.0),
    ]) {
      testWidgets('clock on one line at ${width.toInt()}dp x $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ActiveTimerCard(timer: timer, onStop: () {}),
            ),
          ),
        ));

        expect(tester.takeException(), isNull);
        final clock =
            tester.renderObject<RenderParagraph>(find.text('00:05:30'));
        expect(_lines(clock), 1,
            reason: 'the clock wrapped');
        final label =
            tester.renderObject<RenderParagraph>(find.text('Breast (left)'));
        // Two words may take two lines at 3.0; four or more lines is the
        // old letter-by-letter break.
        expect(_lines(label), lessThanOrEqualTo(2),
            reason: 'the label broke up');
        expect(find.text('STOP').hitTestable(), findsOneWidget);
        final stop = tester.getRect(find.text('STOP'));
        expect(stop.right, lessThanOrEqualTo(width));
      });
    }
  });
}

/// How many lines a paragraph was laid out on: its height over the height
/// of the same text on one unbroken line.
int _lines(RenderParagraph p) =>
    (p.size.height / p.getMinIntrinsicHeight(double.infinity)).round();
