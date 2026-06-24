import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/health/medicine/domain/entities/medicine_log.dart';
import 'package:lullaby/features/health/medicine/presentation/controllers/medicine_controller.dart';
import 'package:lullaby/features/health/medicine/presentation/screens/medicine_screen.dart';
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

  final fakeLog = MedicineLogEntity(
    id: 'log1',
    babyId: 'baby1',
    medicineName: 'Tylenol',
    dosage: 2.5,
    dosageUnit: 'ml',
    administeredAt: DateTime(2025, 6, 15, 10),
    createdAt: DateTime(2025, 6, 15),
    modifiedAt: DateTime(2025, 6, 15),
  );

  Widget buildSubject({BabyEntity? baby, List<MedicineLogEntity> logs = const []}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
        medicineLogsProvider.overrideWith(
            (ref, babyId) => Stream.value(logs)),
      ],
      child: const MaterialApp(home: MedicineScreen()),
    );
  }

  group('MedicineScreen', () {
    testWidgets('shows "No baby selected" when no active baby', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby selected'), findsOneWidget);
    });

    testWidgets('shows Medications in appbar', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('Medications'), findsOneWidget);
    });

    testWidgets('shows FAB add button', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no logs', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();
      await tester.pump();

      expect(find.text('No medications logged'), findsOneWidget);
    });

    testWidgets('shows medicine name in list when logs exist', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby, logs: [fakeLog]));
      await tester.pump();
      await tester.pump();

      expect(find.text('Tylenol'), findsOneWidget);
    });

    testWidgets('shows medication icon in list', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby, logs: [fakeLog]));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.medication), findsWidgets);
    });
  });
}
