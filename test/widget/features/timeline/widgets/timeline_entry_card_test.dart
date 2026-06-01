import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
import 'package:lullaby/features/timeline/presentation/widgets/timeline_entry_card.dart';

void main() {
  group('TimelineEntryCard', () {
    testWidgets('renders feeding event', (tester) async {
      final event = TimelineEvent(
        id: '1',
        type: TimelineEventType.feeding,
        time: DateTime(2025, 6, 15, 10, 30),
        title: 'Feeding',
        subtitle: 'Breast (left) - 15min',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TimelineEntryCard(event: event),
        ),
      ));

      expect(find.text('Feeding'), findsOneWidget);
      expect(find.text('Breast (left) - 15min'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('renders sleep event', (tester) async {
      final event = TimelineEvent(
        id: '2',
        type: TimelineEventType.sleep,
        time: DateTime(2025, 6, 15, 14, 0),
        title: 'Sleep',
        subtitle: 'Nap - 1h 30m',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TimelineEntryCard(event: event),
        ),
      ));

      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Nap - 1h 30m'), findsOneWidget);
      expect(find.byIcon(Icons.bedtime), findsOneWidget);
    });

    testWidgets('renders diaper event', (tester) async {
      final event = TimelineEvent(
        id: '3',
        type: TimelineEventType.diaper,
        time: DateTime(2025, 6, 15, 16, 0),
        title: 'Diaper',
        subtitle: 'Wet',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TimelineEntryCard(event: event),
        ),
      ));

      expect(find.text('Diaper'), findsOneWidget);
      expect(find.text('Wet'), findsOneWidget);
      expect(find.byIcon(Icons.baby_changing_station), findsOneWidget);
    });

    testWidgets('renders growth event', (tester) async {
      final event = TimelineEvent(
        id: '4',
        type: TimelineEventType.growth,
        time: DateTime(2025, 6, 15, 9, 0),
        title: 'Measurements',
        subtitle: '8.5 kg · 72.0 cm',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TimelineEntryCard(event: event),
        ),
      ));

      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('8.5 kg · 72.0 cm'), findsOneWidget);
      expect(find.byIcon(Icons.straighten), findsOneWidget);
    });

    testWidgets('renders medicine event', (tester) async {
      final event = TimelineEvent(
        id: '5',
        type: TimelineEventType.medicine,
        time: DateTime(2025, 6, 15, 11, 0),
        title: 'Tylenol',
        subtitle: '5 ml',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TimelineEntryCard(event: event),
        ),
      ));

      expect(find.text('Tylenol'), findsOneWidget);
      expect(find.text('5 ml'), findsOneWidget);
      expect(find.byIcon(Icons.medication), findsOneWidget);
    });

    testWidgets('renders vaccine event', (tester) async {
      final event = TimelineEvent(
        id: '6',
        type: TimelineEventType.vaccine,
        time: DateTime(2025, 6, 15, 13, 0),
        title: 'MMR (dose 1)',
        subtitle: 'Given',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TimelineEntryCard(event: event),
        ),
      ));

      expect(find.text('MMR (dose 1)'), findsOneWidget);
      expect(find.text('Given'), findsOneWidget);
      expect(find.byIcon(Icons.vaccines), findsOneWidget);
    });
  });
}
