import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/router.dart';
import 'package:lullaby/app/undo_host.dart';
import 'package:lullaby/core/providers/database_provider.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/services/database/database.dart';

import '../../test_setup.dart';

/// Operator ruling Q1: a deliberate delete does not ask; it deletes and
/// offers an Undo that never times out, and that Undo must outlive the edit
/// form that closes straight after the delete. An easy gesture (a swipe)
/// asks first, with a button that names the act.
void main() {
  ensureSqlite3();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  final now = DateTime(2026, 1, 1, 9);

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      await db.babyDao.insertBaby(BabiesCompanion.insert(
        id: 'b1',
        name: 'Nora',
        dateOfBirth: DateTime(2025, 11, 1),
        createdAt: now,
        modifiedAt: now,
      ));
      await db.feedingDao.insertFeeding(FeedingLogsCompanion.insert(
        id: 'f1',
        babyId: 'b1',
        type: 'bottle',
        startTime: now,
        createdAt: now,
        modifiedAt: now,
      ));
      await db.growthDao.insertGrowthRecord(GrowthRecordsCompanion.insert(
        id: 'g1',
        babyId: 'b1',
        measuredAt: now,
        createdAt: now,
        modifiedAt: now,
      ));
    });

    router.go('/dashboard');
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => UndoHost(child: child!),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    unawaited(db.close());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<int> feedCount(WidgetTester tester) async =>
      (await tester.runAsync(() => db.feedingDao.getAllForBaby('b1')))!
          .length;

  testWidgets(
      'deleting a feed from its edit form does not ask, and Undo outlives '
      'the form and never times out', (tester) async {
    await pumpApp(tester);
    router.push(
      '/feeding',
      extra: FeedingLogEntity(
        id: 'f1',
        babyId: 'b1',
        type: FeedingType.bottle,
        startTime: now,
        createdAt: now,
        modifiedAt: now,
      ),
    );
    await tester.pumpAndSettle();

    // Delete is worded and drawn in the urgency colour, not the accent.
    final deleteLabel = tester.element(find.text('Delete'));
    expect(DefaultTextStyle.of(deleteLabel).style.color,
        Theme.of(deleteLabel).colorScheme.error);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing,
        reason: 'a deliberate delete must not ask first');
    expect(find.text('Edit Feeding'), findsNothing,
        reason: 'the form closes after the delete');
    expect(await feedCount(tester), 0);
    expect(find.text('Feed deleted'), findsOneWidget);

    await tester.pump(const Duration(hours: 1));
    expect(find.text('Undo'), findsOneWidget,
        reason: 'the Undo offer must never time out');

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await feedCount(tester), 1);
    expect(find.text('Feed deleted'), findsNothing);

    await tearDownApp(tester);
  });

  testWidgets('swiping a measurement away asks, naming the act',
      (tester) async {
    await pumpApp(tester);
    router.push('/growth');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final row = find.byType(Dismissible).first;
    await tester.ensureVisible(row);
    await tester.drag(row, const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete measurement'), findsOneWidget,
        reason: 'the confirm button names what it deletes');
    await tester.tap(find.text('Delete measurement'));
    await tester.pumpAndSettle();

    final left = await tester
        .runAsync(() => db.growthDao.getAllForBaby('b1'));
    expect(left, isEmpty);

    await tearDownApp(tester);
  });
}
