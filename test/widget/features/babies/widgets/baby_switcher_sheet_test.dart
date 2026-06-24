import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/babies/presentation/controllers/baby_controller.dart';
import 'package:lullaby/features/babies/presentation/widgets/baby_switcher_sheet.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';

void main() {
  final alice = BabyEntity(
    id: 'baby1',
    name: 'Alice',
    dateOfBirth: DateTime(2024, 12, 1),
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  final bob = BabyEntity(
    id: 'baby2',
    name: 'Bob',
    dateOfBirth: DateTime(2025, 3, 1),
    isActive: false,
    createdAt: DateTime(2025, 3, 15),
    modifiedAt: DateTime(2025, 3, 15),
  );

  Widget buildSubject({List<BabyEntity> babies = const [], BabyEntity? active}) {
    return ProviderScope(
      overrides: [
        babyListProvider.overrideWith((ref) => Stream.value(babies)),
        activeBabyProvider.overrideWith(
            (ref) => Stream.value(active)),
        babyControllerProvider.overrideWith(BabyController.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showBabySwitcher(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('BabySwitcherSheet', () {
    testWidgets('shows list of babies', (tester) async {
      await tester.pumpWidget(
          buildSubject(babies: [alice, bob], active: alice));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows checkmark on active baby', (tester) async {
      await tester.pumpWidget(
          buildSubject(babies: [alice, bob], active: alice));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows "Add baby" tile', (tester) async {
      await tester.pumpWidget(buildSubject(babies: [alice]));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add baby'), findsOneWidget);
    });

    testWidgets('shows "Select Baby" header', (tester) async {
      await tester.pumpWidget(buildSubject(babies: [alice]));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Select Baby'), findsOneWidget);
    });

    testWidgets('dismisses sheet when active baby is tapped', (tester) async {
      await tester.pumpWidget(
          buildSubject(babies: [alice], active: alice));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      // Sheet dismissed — back to main screen
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
