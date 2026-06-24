import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/health/vaccine/domain/entities/vaccine_record.dart';
import 'package:lullaby/features/health/vaccine/presentation/controllers/vaccine_controller.dart';
import 'package:lullaby/features/health/vaccine/presentation/screens/vaccine_add_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';

class _FakeVaccineController extends VaccineController {
  final List<String> calls = [];

  @override
  Future<Result<VaccineRecordEntity>> add({
    required String babyId,
    required String vaccineName,
    int? doseNumber,
    DateTime? scheduledDate,
    DateTime? administeredDate,
    String? provider,
    String? notes,
  }) async {
    calls.add('add:$vaccineName');
    state = const AsyncData(null);
    return Success(VaccineRecordEntity(
      id: 'new',
      babyId: babyId,
      vaccineName: vaccineName,
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

  final fakeVaccineRecord = VaccineRecordEntity(
    id: 'rec1',
    babyId: 'baby1',
    vaccineName: 'MMR',
    doseNumber: 1,
    scheduledDate: DateTime(2025, 6, 1),
    createdAt: DateTime(2025, 6, 1),
    modifiedAt: DateTime(2025, 6, 1),
  );

  // Create mode: plain MaterialApp — GoRouterState.maybeOf returns null, no edit mode
  Widget buildSubject({_FakeVaccineController? controller}) {
    final ctrl = controller ?? _FakeVaccineController();
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith(
            (ref) => Stream.value(fakeBaby)),
        vaccineControllerProvider.overrideWith(() => ctrl),
      ],
      child: const MaterialApp(home: VaccineAddScreen()),
    );
  }

  // Edit mode: two-route GoRouter so extra is delivered via GoRouterState
  Widget buildEditMode({_FakeVaccineController? controller}) {
    final ctrl = controller ?? _FakeVaccineController();
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  router.push('/vaccines/add', extra: fakeVaccineRecord),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/vaccines/add',
          builder: (ctx, _) => const VaccineAddScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
        vaccineControllerProvider.overrideWith(() => ctrl),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('VaccineAddScreen', () {
    testWidgets('shows "Add Vaccine" appbar title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Add Vaccine'), findsOneWidget);
    });

    testWidgets('shows vaccine name field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Vaccine name'), findsOneWidget);
    });

    testWidgets('shows quick-select chips', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.widgetWithText(ActionChip, 'DTaP'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'MMR'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Flu'), findsOneWidget);
    });

    testWidgets('tapping chip fills vaccine name field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.widgetWithText(ActionChip, 'DTaP'));
      await tester.pump();

      final field = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Vaccine name'));
      expect(field.controller?.text, 'DTaP');
    });

    testWidgets('shows Save button', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      final controller = _FakeVaccineController();
      await tester.pumpWidget(buildSubject(controller: controller));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Vaccine name'), 'MMR');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(controller.calls, contains('add:MMR'));
    });

    testWidgets('shows dose number field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
          find.widgetWithText(TextFormField, 'Dose number (optional)'),
          findsOneWidget);
    });

    testWidgets('shows scheduled date tile', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Scheduled date (optional)'), findsOneWidget);
    });
  });

  group('edit mode', () {
    testWidgets('shows "Edit Vaccine" title when extra is VaccineRecordEntity',
        (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Vaccine'), findsOneWidget);
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
