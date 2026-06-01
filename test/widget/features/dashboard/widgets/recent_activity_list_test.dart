import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/recent_activity_list.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';

void main() {
  group('RecentActivityList', () {
    testWidgets('shows empty message when no events', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RecentActivityList(events: []),
        ),
      ));

      expect(find.text('No activity yet today.\nTap a button above to start logging!'),
          findsOneWidget);
    });

    testWidgets('renders events when provided', (tester) async {
      final events = [
        TimelineEvent(
          id: '1',
          type: TimelineEventType.feeding,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          title: 'Feeding',
          subtitle: 'Breast (left)',
        ),
        TimelineEvent(
          id: '2',
          type: TimelineEventType.diaper,
          time: DateTime.now().subtract(const Duration(minutes: 30)),
          title: 'Diaper',
          subtitle: 'Wet',
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecentActivityList(events: events),
          ),
        ),
      ));

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Feeding'), findsOneWidget);
      expect(find.text('Diaper'), findsOneWidget);
    });

    testWidgets('shows correct icons', (tester) async {
      final events = [
        TimelineEvent(
          id: '1',
          type: TimelineEventType.sleep,
          time: DateTime.now(),
          title: 'Sleep',
          subtitle: 'Nap',
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecentActivityList(events: events),
          ),
        ),
      ));

      expect(find.byIcon(Icons.bedtime), findsOneWidget);
    });
  });
}
