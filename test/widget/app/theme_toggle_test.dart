import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/router.dart';
import 'package:lullaby/core/providers/database_provider.dart';
import 'package:lullaby/features/settings/presentation/controllers/theme_controller.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sanctuary_backup_ui/testing.dart';

import '../../test_setup.dart';

/// Operator ruling Q3: switching theme stays one tap, at most two, from
/// every primary screen. The toggle lives in the shell's app bar, so all
/// four tabs carry it.
void main() {
  ensureSqlite3();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, {Size size = const Size(360, 800),
      double scale = 1.0}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
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
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      themeStorageProvider.overrideWithValue(InMemorySecretStorage()),
    ]);
    router.go('/dashboard');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    container.dispose();
    unawaited(db.close());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('every tab reaches Dark in two taps', (tester) async {
    await pumpApp(tester);
    final tabs = ['Home', 'Timeline', 'Baby', 'Health'];
    final choices = [
      OhThemeModePreference.dark,
      OhThemeModePreference.light,
      OhThemeModePreference.system,
      OhThemeModePreference.dark,
    ];
    for (var i = 0; i < tabs.length; i++) {
      await tester.tap(find.text(tabs[i]).last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OhThemeToggle), findsOneWidget,
          reason: '${tabs[i]} has the theme toggle');
      await tester.tap(find.byType(OhThemeToggle)); // tap 1: open the menu
      await tester.pumpAndSettle();
      await tester.tap(find.text(choices[i].label).last); // tap 2: choose
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), choices[i]);
    }
    await tearDownApp(tester);
  });

  testWidgets('the shell bar fits at 320dp and text scale 3.0',
      (tester) async {
    await pumpApp(tester, size: const Size(320, 640), scale: 3.0);
    expect(tester.takeException(), isNull);
    expect(find.byType(OhThemeToggle), findsOneWidget);
    await tearDownApp(tester);
  });
}
