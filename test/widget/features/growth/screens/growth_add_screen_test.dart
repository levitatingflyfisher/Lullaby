import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/screens/growth_add_screen.dart';
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
    id: 'rec1',
    babyId: 'baby1',
    measuredAt: DateTime(2025, 6, 1),
    weightKg: 7.2,
    heightCm: 65.0,
    createdAt: DateTime(2025, 6, 1),
    modifiedAt: DateTime(2025, 6, 1),
  );

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
      ],
      child: const MaterialApp(home: GrowthAddScreen()),
    );
  }

  Widget buildEditMode() {
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, _) => Scaffold(
            body: TextButton(
              onPressed: () => router.push('/growth/add', extra: fakeRecord),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/growth/add',
          builder: (ctx, _) => const GrowthAddScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('GrowthAddScreen', () {
    testWidgets('renders form fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Add Measurement'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);
      expect(find.text('Head circumference (cm)'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
    });

    testWidgets('shows Save button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows date tile', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid weight', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Enter invalid weight
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Weight (kg)'), '999');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Enter a valid weight (0-30 kg)'), findsOneWidget);
    });

    testWidgets('shows snackbar when no measurements entered', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Tap Save without entering any measurements
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Enter at least one measurement'), findsOneWidget);
    });

    testWidgets('accepts valid weight input', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Weight (kg)'), '6.5');
      await tester.pump();

      // No validation error shown yet
      expect(find.text('Enter a valid weight (0-30 kg)'), findsNothing);
    });
  });

  group('edit mode', () {
    testWidgets('shows "Edit Measurement" title when extra is GrowthRecordEntity',
        (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Measurement'), findsOneWidget);
    });

    testWidgets('shows delete icon in AppBar in edit mode', (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
