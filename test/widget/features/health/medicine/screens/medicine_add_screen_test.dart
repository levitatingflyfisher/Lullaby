import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/health/medicine/domain/entities/medicine_log.dart';
import 'package:lullaby/features/health/medicine/presentation/controllers/medicine_controller.dart';
import 'package:lullaby/features/health/medicine/presentation/screens/medicine_add_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';

class _FakeMedicineController extends MedicineController {
  final List<String> calls = [];

  @override
  Future<Result<MedicineLogEntity>> add({
    required String babyId,
    required String medicineName,
    double? dosage,
    String? dosageUnit,
    required DateTime administeredAt,
    String? notes,
  }) async {
    calls.add('add:$medicineName');
    state = const AsyncData(null);
    return Success(MedicineLogEntity(
      id: 'new',
      babyId: babyId,
      medicineName: medicineName,
      administeredAt: administeredAt,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    ));
  }
}

void main() {
  final fakeBaby = BabyEntity(
    id: 'baby1',
    name: 'Alice',
    dateOfBirth: DateTime(2024, 12, 1),
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  final fakeMedicineLog = MedicineLogEntity(
    id: 'log1',
    babyId: 'baby1',
    medicineName: 'Tylenol',
    dosage: 2.5,
    dosageUnit: 'ml',
    administeredAt: DateTime(2025, 6, 15, 10),
    createdAt: DateTime(2025, 6, 15),
    modifiedAt: DateTime(2025, 6, 15),
  );

  // Create mode: plain MaterialApp — GoRouterState.maybeOf returns null, no edit mode
  Widget buildSubject({_FakeMedicineController? controller}) {
    final ctrl = controller ?? _FakeMedicineController();
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith(
            (ref) => Stream.value(fakeBaby)),
        medicineControllerProvider.overrideWith(() => ctrl),
      ],
      child: const MaterialApp(home: MedicineAddScreen()),
    );
  }

  // Edit mode: two-route GoRouter so extra is delivered via GoRouterState
  Widget buildEditMode({_FakeMedicineController? controller}) {
    final ctrl = controller ?? _FakeMedicineController();
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  router.push('/medicine/add', extra: fakeMedicineLog),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/medicine/add',
          builder: (ctx, _) => const MedicineAddScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
        medicineControllerProvider.overrideWith(() => ctrl),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('MedicineAddScreen', () {
    testWidgets('shows "Add Medication" appbar title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Add Medication'), findsOneWidget);
    });

    testWidgets('shows medicine name field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Medicine name'), findsOneWidget);
    });

    testWidgets('shows dosage field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
          find.widgetWithText(TextFormField, 'Dosage (optional)'),
          findsOneWidget);
    });

    testWidgets('shows Save button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('calls controller.add when form is valid', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = _FakeMedicineController();
      await tester.pumpWidget(buildSubject(controller: controller));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Medicine name'), 'Tylenol');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(controller.calls, contains('add:Tylenol'));
    });

    testWidgets('shows date & time tile', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Date & Time'), findsOneWidget);
    });

    testWidgets('shows notes field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
          find.widgetWithText(TextFormField, 'Notes (optional)'),
          findsOneWidget);
    });
  });

  group('edit mode', () {
    testWidgets('shows "Edit Medication" title when extra is MedicineLogEntity',
        (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Medication'), findsOneWidget);
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
