import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/controllers/growth_controller.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/stats/presentation/controllers/stats_controller.dart';
import 'package:lullaby/features/stats/presentation/widgets/period_selector.dart';
import 'package:lullaby/features/timeline/presentation/widgets/charts_tab.dart';

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
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
        dailySummariesProvider.overrideWith((ref, babyId) async => []),
        growthRecordsProvider.overrideWith(
            (ref, babyId) => Stream.value(<GrowthRecordEntity>[])),
      ],
      child: const MaterialApp(home: Scaffold(body: ChartsTab())),
    );
  }

  group('ChartsTab', () {
    testWidgets('shows "No baby selected" when no baby', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby selected'), findsOneWidget);
    });

    testWidgets('shows PeriodSelector when baby is active', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump(); // stream
      await tester.pump(); // future

      expect(find.byType(PeriodSelector), findsOneWidget);
    });

    testWidgets('shows 7d period button by default', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(find.text('7d'), findsOneWidget);
    });
  });
}
