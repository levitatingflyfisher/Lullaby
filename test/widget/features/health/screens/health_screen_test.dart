import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/health/presentation/screens/health_screen.dart';
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

  Widget buildSubject({BabyEntity? baby}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
      ],
      child: const MaterialApp(home: HealthScreen()),
    );
  }

  group('HealthScreen', () {
    testWidgets('shows "No baby selected" when no active baby', (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby selected'), findsOneWidget);
    });

    testWidgets('shows Medications card when baby is selected', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.text('Medications'), findsOneWidget);
    });

    testWidgets('shows Vaccines card when baby is selected', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.text('Vaccines'), findsOneWidget);
    });

    testWidgets('shows baby name in header', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows both health cards', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.byType(Card), findsNWidgets(2));
    });
  });
}
