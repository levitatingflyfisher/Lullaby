import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/doctor/presentation/controllers/doctor_controller.dart';
import 'package:lullaby/features/doctor/presentation/screens/doctor_summary_screen.dart';
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

  final now = DateTime.now();
  final fakeSummary = DoctorSummary(
    baby: fakeBaby,
    dateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)), end: now),
    avgFeedsPerDay: 8.5,
    avgSleepHoursPerDay: 14.2,
    avgDiapersPerDay: 6.3,
    latestGrowth: null,
  );

  Widget buildSubject({BabyEntity? baby, DoctorSummary? summary}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider
            .overrideWith((ref) => Stream.value(baby)),
        doctorSummaryProvider
            .overrideWith((ref, b) async => summary),
      ],
      child: const MaterialApp(home: DoctorSummaryScreen()),
    );
  }

  group('DoctorSummaryScreen', () {
    testWidgets('shows "Doctor Summary" in appbar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Doctor Summary'), findsOneWidget);
    });

    testWidgets('shows "No baby selected" when no active baby', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby selected'), findsOneWidget);
    });

    testWidgets('shows baby name in summary', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows Feeding section', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      expect(find.text('Feeding'), findsOneWidget);
    });

    testWidgets('shows Sleep section', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sleep'), findsOneWidget);
    });

    testWidgets('shows Diapers section', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      expect(find.text('Diapers'), findsOneWidget);
    });

    testWidgets('shows Growth section', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      expect(find.text('Growth'), findsOneWidget);
    });

    testWidgets('shows averages', (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      // avgFeedsPerDay = 8.5
      expect(find.text('8.5'), findsWidgets);
    });

    testWidgets('shows "No growth measurements" when latestGrowth is null',
        (tester) async {
      await tester.pumpWidget(
          buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      expect(find.text('No growth measurements recorded'), findsOneWidget);
    });

    testWidgets('share icon is present in AppBar when summary is loaded',
        (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('share icon onPressed is null while dailies are loading',
        (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby, summary: fakeSummary));
      await tester.pump();
      await tester.pump();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.share),
      );
      expect(iconButton.onPressed, isNull);
    });
  });
}
