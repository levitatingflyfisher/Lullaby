import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
import 'package:lullaby/features/timeline/presentation/widgets/events_tab.dart';

void main() {
  final fakeBaby = BabyEntity(
    id: 'baby1',
    name: 'Alice',
    dateOfBirth: DateTime(2024, 12, 1),
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  Widget buildSubject({BabyEntity? baby, List<TimelineEvent> events = const []}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
        timelineProvider.overrideWith((ref, babyId) => Stream.value(events)),
      ],
      child: const MaterialApp(home: Scaffold(body: EventsTab())),
    );
  }

  group('EventsTab', () {
    testWidgets('shows filter chips when baby is active', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      // TimelineFilterChips renders one chip per TimelineFilter value (All, Feeding, Sleep, …)
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Feeding'), findsOneWidget);
    });

    testWidgets('shows "No events yet" when event list is empty', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump(); // activeBabyProvider stream
      await tester.pump(); // timelineProvider stream

      expect(find.text('No events yet'), findsOneWidget);
    });

    testWidgets('shows no-baby message when baby is null', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Add a baby to see events'), findsOneWidget);
    });
  });
}
