import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/daily_summary_strip.dart';

void main() {
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
