import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/doctor/presentation/controllers/doctor_controller.dart';
import 'package:lullaby/features/export/export_bottom_sheet.dart';

void main() {
  final now = DateTime(2026, 3, 27);
  final baby = BabyEntity(
    id: 'b1',
    name: 'TestBaby',
    dateOfBirth: DateTime(2025, 9, 1),
    isActive: true,
    createdAt: now,
    modifiedAt: now,
  );
  final summary = DoctorSummary(
    baby: baby,
    dateRange:
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    avgFeedsPerDay: 8.0,
    avgSleepHoursPerDay: 14.5,
    avgDiapersPerDay: 6.0,
  );

  Widget buildSubject() {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ExportBottomSheet(
            summary: summary,
            dailySummaries: const [],
          ),
        ),
      ),
    );
  }

  group('ExportBottomSheet', () {
    testWidgets('renders PDF Summary list tile', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('PDF Summary'), findsOneWidget);
    });

    testWidgets('renders CSV Summary list tile', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('CSV Summary'), findsOneWidget);
    });

    testWidgets('both tiles are present simultaneously', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('PDF Summary'), findsOneWidget);
      expect(find.text('CSV Summary'), findsOneWidget);
    });

    testWidgets('PDF icon is present', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('CSV icon is present', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });
  });
}
