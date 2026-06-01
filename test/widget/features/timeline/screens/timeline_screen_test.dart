import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/controllers/growth_controller.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/stats/presentation/controllers/stats_controller.dart';
import 'package:lullaby/features/timeline/presentation/controllers/timeline_controller.dart';
import 'package:lullaby/features/timeline/presentation/screens/timeline_screen.dart';

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
        timelineProvider.overrideWith(
            (ref, babyId) => Stream.value([])),
      ],
      child: const MaterialApp(home: TimelineScreen()),
    );
  }

  group('TimelineScreen', () {
    testWidgets('shows "Timeline" in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Timeline'), findsOneWidget);
    });

    testWidgets('shows Charts and Events tabs', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Charts'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('default tab is Charts', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      // PeriodSelector is only in ChartsTab
      expect(find.text('7d'), findsOneWidget);
    });

    testWidgets('tapping Events tab shows filter chips', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      // TimelineFilterChips renders "All" chip
      expect(find.text('All'), findsOneWidget);
    });
  });
}
