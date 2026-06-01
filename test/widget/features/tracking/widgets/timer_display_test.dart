import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/tracking/presentation/widgets/timer_display.dart';

void main() {
  group('TimerDisplay', () {
    testWidgets('renders formatted elapsed time', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TimerDisplay(elapsed: Duration(hours: 1, minutes: 23, seconds: 45)),
        ),
      ));

      expect(find.text('01:23:45'), findsOneWidget);
    });

    testWidgets('renders zero duration', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TimerDisplay(elapsed: Duration.zero),
        ),
      ));

      expect(find.text('00:00:00'), findsOneWidget);
    });

    testWidgets('pads single digits', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TimerDisplay(elapsed: Duration(minutes: 5, seconds: 3)),
        ),
      ));

      expect(find.text('00:05:03'), findsOneWidget);
    });
  });
}
