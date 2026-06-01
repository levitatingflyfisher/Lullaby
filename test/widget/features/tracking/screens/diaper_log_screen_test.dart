import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/features/tracking/presentation/controllers/diaper_controller.dart';
import 'package:lullaby/features/tracking/presentation/screens/diaper_log_screen.dart';

class _FakeDiaperController extends DiaperController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<Result<void>> deleteLog(String id) async => const Success(null);
}

void main() {
  final fakeDiaperLog = DiaperLogEntity(
    id: 'd1',
    babyId: 'baby1',
    time: DateTime(2025, 6, 15, 8, 0),
    type: DiaperType.wet,
    createdAt: DateTime(2025, 6, 15),
    modifiedAt: DateTime(2025, 6, 15),
  );

  Widget buildCreateMode() {
    final router = GoRouter(
      initialLocation: '/diaper',
      routes: [
        GoRoute(
          path: '/diaper',
          builder: (ctx, _) => const DiaperLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        diaperControllerProvider.overrideWith(() => _FakeDiaperController()),
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
              onPressed: () => router.push('/diaper', extra: fakeDiaperLog),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/diaper',
          builder: (ctx, _) => const DiaperLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        diaperControllerProvider.overrideWith(() => _FakeDiaperController()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('DiaperLogScreen', () {
    testWidgets('create mode shows "Log Diaper" title', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.text('Log Diaper'), findsOneWidget);
    });

    testWidgets('create mode has no delete button', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('edit mode shows "Edit Diaper" title', (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Diaper'), findsOneWidget);
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
