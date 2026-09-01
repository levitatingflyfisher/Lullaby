import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/router.dart';
import 'package:lullaby/core/providers/database_provider.dart';
import 'package:lullaby/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:lullaby/features/doctor/presentation/screens/doctor_summary_screen.dart';
import 'package:lullaby/features/growth/presentation/screens/growth_screen.dart';
import 'package:lullaby/services/database/database.dart';

import '../../test_setup.dart';

/// lullaby:dmmt-03 — Growth, Calendar and Doctor Summary were registered
/// routes with no caller. Each test starts on Home with the real router and
/// a real (in-memory) database, and reaches the screen by tapping only.
void main() {
  ensureSqlite3();
  // One fresh in-memory database per test, never shared.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime(2026, 1, 1);
    await tester.runAsync(() => db.babyDao.insertBaby(BabiesCompanion.insert(
          id: 'b1',
          name: 'Nora',
          dateOfBirth: DateTime(2025, 11, 1),
          createdAt: now,
          modifiedAt: now,
        )));

    router.go('/dashboard');
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Feed'), findsOneWidget, reason: 'did not land on Home');
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    // Unmount first so Drift's stream subscriptions cancel, then close.
    await tester.pumpWidget(const SizedBox());
    // Drift schedules a zero-length timer as each stream query is cancelled.
    await tester.pump(const Duration(milliseconds: 1));
    // Awaiting close() inside runAsync hangs under the test binding; start it
    // in the fake zone and let a pump flush it instead.
    unawaited(db.close());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // The destination screens may show a spinner while their first query
  // resolves, which never "settles"; pump through the route transition only.
  Future<void> tapDoor(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Home -> Timeline -> Growth details opens Growth',
      (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Timeline'));
    await tapDoor(tester, find.text('Growth details'));
    expect(find.byType(GrowthScreen), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Home -> Timeline -> Events -> Calendar opens Calendar',
      (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Timeline'));
    await tapVisible(tester, find.text('Events'));
    await tapDoor(tester, find.text('Calendar'));
    expect(find.byType(CalendarScreen), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Home -> Baby -> Summary for the doctor opens Doctor Summary',
      (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Baby'));
    await tapDoor(tester, find.text('Summary for the doctor'));
    expect(find.byType(DoctorSummaryScreen), findsOneWidget);
    await tearDownApp(tester);
  });
}
