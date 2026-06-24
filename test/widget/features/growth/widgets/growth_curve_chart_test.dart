import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/widgets/growth_curve_chart.dart';

void main() {
  final dateOfBirth = DateTime(2024, 12, 1);
  final now = DateTime(2025, 6, 15);

  GrowthRecordEntity makeRecord(double? weightKg, double? heightCm) =>
      GrowthRecordEntity(
        id: 'r1',
        babyId: 'baby1',
        measuredAt: now,
        weightKg: weightKg,
        heightCm: heightCm,
        createdAt: now,
        modifiedAt: now,
      );

  group('GrowthCurveChart', () {
    testWidgets('renders tab bar with Weight, Height, Head', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GrowthCurveChart(
            records: [makeRecord(5.5, 60.0)],
            dateOfBirth: dateOfBirth,
            gender: Gender.male,
          ),
        ),
      ));

      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Head'), findsOneWidget);
    });

    testWidgets('renders with empty records list', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GrowthCurveChart(
            records: const [],
            dateOfBirth: dateOfBirth,
            gender: Gender.female,
          ),
        ),
      ));

      expect(find.text('Growth Curves'), findsOneWidget);
    });

    testWidgets('shows a set-sex hint instead of curves when gender is null',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GrowthCurveChart(
            records: [makeRecord(5.5, null)],
            dateOfBirth: dateOfBirth,
            gender: null,
          ),
        ),
      ));

      expect(find.text('Growth Curves'), findsOneWidget);
      // No fabricated boys' curves — prompt for the sex instead (M8).
      expect(find.textContaining('sex'), findsOneWidget);
    });

    testWidgets('switches tab to Height on tap', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GrowthCurveChart(
            records: [makeRecord(5.5, 60.0)],
            dateOfBirth: dateOfBirth,
            gender: Gender.male,
          ),
        ),
      ));

      await tester.tap(find.text('Height'));
      await tester.pumpAndSettle();

      // Tab still visible after switch
      expect(find.text('Height'), findsOneWidget);
    });
  });
}
