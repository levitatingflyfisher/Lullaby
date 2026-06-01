import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:lullaby/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:table_calendar/table_calendar.dart' show TableCalendar;

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
        activeBabyProvider
            .overrideWith((ref) => Stream.value(baby)),
        calendarEventsProvider
            .overrideWith((ref, range) async => {}),
      ],
      child: const MaterialApp(home: CalendarScreen()),
    );
  }

  group('CalendarScreen', () {
    testWidgets('shows Calendar in appbar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Calendar'), findsOneWidget);
    });

    testWidgets('shows "No baby selected" when no active baby', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby selected'), findsOneWidget);
    });

    testWidgets('renders TableCalendar when baby exists', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is TableCalendar),
        findsOneWidget,
      );
    });
  });
}
