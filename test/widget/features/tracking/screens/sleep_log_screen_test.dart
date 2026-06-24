import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/tracking/domain/entities/sleep_log.dart';
import 'package:lullaby/features/tracking/presentation/controllers/sleep_controller.dart';
import 'package:lullaby/features/tracking/presentation/screens/sleep_log_screen.dart';

class _FakeSleepController extends SleepController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<Result<void>> deleteLog(String id) async => const Success(null);
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

  final fakeSleepLog = SleepLogEntity(
    id: 's1',
    babyId: 'baby1',
    startTime: DateTime(2025, 6, 15, 14, 0),
    type: SleepType.nap,
    createdAt: DateTime(2025, 6, 15),
    modifiedAt: DateTime(2025, 6, 15),
  );

  Widget buildCreateMode() {
    final router = GoRouter(
      initialLocation: '/sleep',
      routes: [
        GoRoute(
          path: '/sleep',
          builder: (ctx, _) => const SleepLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
        sleepControllerProvider.overrideWith(() => _FakeSleepController()),
      ],
      child: MaterialApp.router(routerConfig: router),
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
              onPressed: () => router.push('/sleep', extra: fakeSleepLog),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/sleep',
          builder: (ctx, _) => const SleepLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
        sleepControllerProvider.overrideWith(() => _FakeSleepController()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SleepLogScreen', () {
    testWidgets('create mode shows "Log Sleep" title', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.text('Log Sleep'), findsOneWidget);
    });

    testWidgets('create mode has no delete button', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('edit mode shows "Edit Sleep" title', (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Sleep'), findsOneWidget);
    });

    testWidgets('edit mode shows delete icon in AppBar', (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
