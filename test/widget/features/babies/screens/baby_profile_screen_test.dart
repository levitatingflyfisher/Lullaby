import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/babies/presentation/screens/baby_profile_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';

void main() {
  final now = DateTime(2026, 3, 27);
  final fakeBaby = BabyEntity(
    id: 'b1',
    name: 'Alice',
    dateOfBirth: DateTime(2025, 9, 1),
    isActive: true,
    createdAt: now,
    modifiedAt: now,
  );

  Widget buildSubject({BabyEntity? baby}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
      ],
      child: const MaterialApp(home: BabyProfileScreen()),
    );
  }

  group('BabyProfileScreen', () {
    testWidgets('shows "Export all data" ListTile when baby is loaded',
        (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.text('Export all data'), findsOneWidget);
    });

    testWidgets('shows baby name', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows "No baby profile yet" when baby is null',
        (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby profile yet'), findsOneWidget);
    });

    testWidgets('download icon is present on export tile', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });
}
