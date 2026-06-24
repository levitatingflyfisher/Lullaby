import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
