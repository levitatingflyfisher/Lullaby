import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/router.dart';
import 'package:lullaby/app/theme/theme.dart';
import 'package:lullaby/core/providers/database_provider.dart';
import 'package:lullaby/features/babies/presentation/screens/baby_edit_screen.dart';
import 'package:lullaby/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lullaby/features/tracking/presentation/screens/feeding_log_screen.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

import '../test_setup.dart';

/// Release gate (roadmap item 24): at 360dp × 1.3 text each primary
/// screen's main action is on screen and tappable (scrolling to it is
/// fine), then the same screen survives 320dp × 3.0 without overflowing.
/// Each screen is reached through the real router with the app's own theme
/// and an in-memory database, as a parent would reach it.
void main() {
  ensureSqlite3();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  AppDatabase? db;

  Future<void> pumpRoute(
    WidgetTester tester,
    String location,
    Type screen, {
    bool withBaby = true,
  }) async {
    await tester.pumpWidget(const SizedBox());
    final old = db;
    if (old != null) {
      await tester.pump(const Duration(milliseconds: 1));
      unawaited(old.close());
    }
    final fresh = AppDatabase.forTesting(NativeDatabase.memory());
    db = fresh;
    if (withBaby) {
      final now = DateTime(2026, 1, 1);
      await tester.runAsync(() => fresh.babyDao.insertBaby(
            BabiesCompanion.insert(
              id: 'b1',
              name: 'Nora',
              dateOfBirth: DateTime(2025, 11, 1),
              createdAt: now,
              modifiedAt: now,
            ),
          ));
    }
    router.go(location);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(fresh)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(screen), findsOneWidget,
        reason: '$location did not show $screen');
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    unawaited(db?.close());
    db = null;
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('first run: Add Baby reachable', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () =>
          pumpRoute(tester, '/dashboard', DashboardScreen, withBaby: false),
      primaryAction: find.text('Add Baby'),
    );
    await drain(tester);
  });

  testWidgets('BabyEditScreen: Add Baby reachable', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () =>
          pumpRoute(tester, '/baby/edit', BabyEditScreen, withBaby: false),
      primaryAction: find.text('Add Baby'),
    );
    await drain(tester);
  });

  testWidgets('DashboardScreen: Feed reachable', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => pumpRoute(tester, '/dashboard', DashboardScreen),
      primaryAction: find.text('Feed'),
    );
    await drain(tester);
  });

  testWidgets('FeedingLogScreen: Start reachable', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => pumpRoute(tester, '/feeding', FeedingLogScreen),
      primaryAction: find.text('Start'),
    );
    await drain(tester);
  });
}
