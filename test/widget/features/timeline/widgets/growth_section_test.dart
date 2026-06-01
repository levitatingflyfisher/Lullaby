import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/controllers/growth_controller.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/timeline/presentation/widgets/growth_section.dart';

void main() {
  final fakeBaby = BabyEntity(
    id: 'baby1',
    name: 'Alice',
    dateOfBirth: DateTime(2024, 12, 1),
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  Widget buildSubject({required BabyEntity? baby, List<GrowthRecordEntity> records = const []}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
        growthRecordsProvider.overrideWith(
            (ref, babyId) => Stream.value(records)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GrowthSection())),
      ),
    );
  }

  group('GrowthSection', () {
    testWidgets('shows empty state when no records', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pumpAndSettle();

      expect(find.text('No growth measurements yet'), findsOneWidget);
    });

    testWidgets('shows "Add measurement" button', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pumpAndSettle();

      expect(find.text('Add measurement'), findsOneWidget);
    });

    testWidgets('is empty when no baby selected', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      // SizedBox.shrink — nothing visible, no crash
      expect(find.text('No growth measurements yet'), findsNothing);
      expect(find.text('Add measurement'), findsNothing);
    });
  });
}
