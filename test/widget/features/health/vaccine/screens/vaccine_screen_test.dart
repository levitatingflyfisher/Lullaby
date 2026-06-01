import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/health/vaccine/domain/entities/vaccine_record.dart';
import 'package:lullaby/features/health/vaccine/presentation/controllers/vaccine_controller.dart';
import 'package:lullaby/features/health/vaccine/presentation/screens/vaccine_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';

void main() {
  final fakeBaby = BabyEntity(
    id: 'baby1',
    name: 'Alice',
    dateOfBirth: DateTime(2024, 12, 1),
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  final fakeUpcoming = VaccineRecordEntity(
    id: 'v1',
    babyId: 'baby1',
    vaccineName: 'DTaP',
    scheduledDate: DateTime(2025, 8, 1),
    createdAt: DateTime(2025, 6, 1),
    modifiedAt: DateTime(2025, 6, 1),
  );

  final fakeGiven = VaccineRecordEntity(
    id: 'v2',
    babyId: 'baby1',
    vaccineName: 'MMR',
    administeredDate: DateTime(2025, 6, 1),
    createdAt: DateTime(2025, 6, 1),
    modifiedAt: DateTime(2025, 6, 1),
  );

  Widget buildSubject({
    BabyEntity? baby,
    List<VaccineRecordEntity> records = const [],
  }) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
        vaccineRecordsProvider.overrideWith(
            (ref, babyId) => Stream.value(records)),
      ],
      child: const MaterialApp(home: VaccineScreen()),
    );
  }

  group('VaccineScreen', () {
    testWidgets('shows "No baby selected" when no active baby', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby selected'), findsOneWidget);
    });

    testWidgets('shows Vaccines in appbar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Vaccines'), findsOneWidget);
    });

    testWidgets('shows Upcoming and Given tabs', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Given'), findsOneWidget);
    });

    testWidgets('shows FAB add button', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows upcoming vaccine in Upcoming tab', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, records: [fakeUpcoming]));
      await tester.pump();
      await tester.pump();

      expect(find.text('DTaP'), findsOneWidget);
    });

    testWidgets('shows administered vaccine in Given tab', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, records: [fakeGiven]));
      await tester.pump();
      await tester.pump();

      // Switch to Given tab
      await tester.tap(find.text('Given'));
      await tester.pumpAndSettle();

      expect(find.text('MMR'), findsOneWidget);
    });

    testWidgets('shows empty state message for Upcoming', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(find.text('No upcoming vaccines'), findsOneWidget);
    });
  });
}
