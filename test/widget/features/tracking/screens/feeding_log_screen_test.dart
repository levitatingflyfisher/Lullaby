import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/presentation/controllers/feeding_controller.dart';
import 'package:lullaby/features/tracking/presentation/screens/feeding_log_screen.dart';

class _FakeFeedingController extends FeedingController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<Result<void>> deleteLog(String id) async => const Success(null);
}

void main() {
  final fakeFeedingLog = FeedingLogEntity(
    id: 'f1',
    babyId: 'baby1',
    type: FeedingType.breast,
    startTime: DateTime(2025, 6, 15, 10, 0),
    side: BreastSide.left,
    createdAt: DateTime(2025, 6, 15),
    modifiedAt: DateTime(2025, 6, 15),
  );

  Widget buildCreateMode() {
    final router = GoRouter(
      initialLocation: '/feeding',
      routes: [
        GoRoute(
          path: '/feeding',
          builder: (ctx, _) => const FeedingLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        feedingControllerProvider.overrideWith(() => _FakeFeedingController()),
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
              onPressed: () => router.push('/feeding', extra: fakeFeedingLog),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          path: '/feeding',
          builder: (ctx, _) => const FeedingLogScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        feedingControllerProvider.overrideWith(() => _FakeFeedingController()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('FeedingLogScreen', () {
    testWidgets('create mode shows "Log Feeding" title', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.text('Log Feeding'), findsOneWidget);
    });

    testWidgets('create mode has no delete button', (tester) async {
      await tester.pumpWidget(buildCreateMode());
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('edit mode shows "Edit Feeding" title', (tester) async {
      await tester.pumpWidget(buildEditMode());
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Feeding'), findsOneWidget);
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
