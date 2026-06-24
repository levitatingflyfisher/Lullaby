import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/stats/presentation/controllers/stats_controller.dart';
import 'package:lullaby/features/stats/presentation/widgets/period_selector.dart';

void main() {
  group('PeriodSelector', () {
    testWidgets('renders all 3 period options', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PeriodSelector(
            selected: StatsPeriod.week,
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('7d'), findsOneWidget);
      expect(find.text('14d'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
    });

    testWidgets('calls onChanged when a segment is tapped', (tester) async {
      StatsPeriod? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PeriodSelector(
            selected: StatsPeriod.week,
            onChanged: (p) => selected = p,
          ),
        ),
      ));

      await tester.tap(find.text('30d'));
      await tester.pumpAndSettle();

      expect(selected, StatsPeriod.month);
    });

    testWidgets('renders SegmentedButton', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PeriodSelector(
            selected: StatsPeriod.twoWeeks,
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.byType(SegmentedButton<StatsPeriod>), findsOneWidget);
    });
  });
}
