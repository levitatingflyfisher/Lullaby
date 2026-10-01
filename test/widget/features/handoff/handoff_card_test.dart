import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/providers/database_provider.dart';
import 'package:lullaby/features/handoff/presentation/handoff_card.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // A focused text field blinks its cursor forever, so these pump fixed
  // frames rather than pumpAndSettle.
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('leaving a note for the next shift shows it on the card', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: Scaffold(body: HandoffCard(babyId: 'b1'))),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester);
    expect(find.text('None yet. Tap to leave one.'), findsOneWidget);

    await tester.tap(find.text('Note for the next shift'));
    await frames(tester);
    // An empty note is not saved, and says why.
    await tester.tap(find.byKey(const Key('handoff-save')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester);
    expect(find.text('Write something first.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('handoff-text')), 'Last feed 3:10, left side.');
    await tester.tap(find.byKey(const Key('handoff-save')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await frames(tester);
    // The sheet lists it under "Earlier" and clears the field for the next.
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Last feed 3:10, left side.'), findsNWidgets(2), reason: 'sheet and card');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(db.close);
  });
}
