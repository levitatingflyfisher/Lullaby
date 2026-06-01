import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/controllers/growth_controller.dart';
import 'package:lullaby/features/growth/presentation/screens/growth_screen.dart';
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

  final fakeRecord = GrowthRecordEntity(
    id: 'r1',
    babyId: 'baby1',
    measuredAt: DateTime(2025, 6, 1),
    weightKg: 7.2,
    heightCm: 65.0,
    createdAt: DateTime(2025, 6, 1),
    modifiedAt: DateTime(2025, 6, 1),
  );

  Widget buildSubject({BabyEntity? baby, GrowthRecordEntity? latest}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith(
            (ref) => Stream.value(baby)),
        growthRecordsProvider.overrideWith(
            (ref, babyId) => Stream.value(latest != null ? [latest] : [])),
        latestGrowthProvider.overrideWith(
            (ref, babyId) async => latest),
      ],
      child: const MaterialApp(home: GrowthScreen()),
    );
  }

  group('GrowthScreen', () {
    testWidgets('shows "No baby selected" when no active baby', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby selected'), findsOneWidget);
    });

    testWidgets('shows Growth in appbar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Growth'), findsOneWidget);
    });

    testWidgets('shows FAB add button', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows "No measurements yet" when no records', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby, latest: null));
      await tester.pump();
      await tester.pump();

      expect(find.text('No measurements yet'), findsOneWidget);
    });

    testWidgets('shows latest measurement when record exists', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby, latest: fakeRecord));
      await tester.pump();
      await tester.pump();

      expect(find.text('Latest Measurement'), findsOneWidget);
      expect(find.text('7.2 kg'), findsOneWidget);
    });

    testWidgets('shows Dismissible for each growth record', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby, latest: fakeRecord));
      await tester.pump();
      await tester.pump();

      expect(find.byType(Dismissible), findsWidgets);
    });
  });
}
