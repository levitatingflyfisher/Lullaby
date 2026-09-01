import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/router.dart';
import 'package:lullaby/core/providers/database_provider.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../test_setup.dart';

/// On a tablet or in a desktop browser the phone layout must not stretch
/// edge to edge: every screen caps its content at OhPage's 640dp and centres
/// it, while app bars and the bottom bar stay full width.
void main() {
  ensureSqlite3();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const wide = Size(1024, 768);
  const routes = [
    '/dashboard', '/timeline', '/baby', '/health',
    '/feeding', '/sleep', '/diaper', '/baby/edit', '/settings',
    '/calendar', '/growth', '/growth/add', '/doctor-summary',
    '/health/medicine', '/health/medicine/add',
    '/health/vaccines', '/health/vaccines/add',
  ];

  testWidgets('every routed screen caps and centres its content at 1024dp',
      (tester) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
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

    for (final route in routes) {
      router.go(route);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final pages = find.byType(OhPage);
      expect(pages, findsWidgets, reason: '$route has no OhPage');
      // The page on top is the last one laid out.
      final box = tester.getRect(find
          .descendant(of: pages.last, matching: find.byType(ConstrainedBox))
          .first);
      expect(box.width, lessThanOrEqualTo(OhPage.phoneMaxWidth),
          reason: '$route content is capped');
      expect(box.center.dx, moreOrLessEquals(wide.width / 2, epsilon: 1),
          reason: '$route content is centred');
      final bar = find.byType(AppBar);
      if (bar.evaluate().isNotEmpty) {
        expect(tester.getSize(bar.last).width, wide.width,
            reason: '$route app bar spans the window');
      }
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    unawaited(db.close());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
