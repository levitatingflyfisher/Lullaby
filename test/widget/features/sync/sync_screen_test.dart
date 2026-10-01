import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:lullaby/core/providers/sync_providers.dart';
import 'package:lullaby/features/sync/data/household_sync.dart';
import 'package:lullaby/features/sync/data/sync_settings_store.dart';
import 'package:lullaby/features/sync/presentation/sync_review_screen.dart';
import 'package:lullaby/features/sync/presentation/sync_screen.dart';
import 'package:lullaby/features/sync/presentation/wifi_sync.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/testing.dart';

import '../../../test_setup.dart';

const words =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const otherWords =
    'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong';

void main() {
  ensureSqlite3();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late HouseholdSync sync;
  late InMemorySecureKeyStore keys;
  var bridgeLoads = 0;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    keys = InMemorySecureKeyStore();
    bridgeLoads = 0;
    sync = HouseholdSync(
      db: db,
      settingsStore: SyncSettingsStore(InMemorySecretStorage()),
      readWords: keys.readMnemonic,
      deriveSeed: OpenHearthMnemonic.deriveSeed,
      signer: () => throw StateError('no key in widget tests'),
      initBridge: () async => bridgeLoads++,
      forgetWords: keys.clearAuth,
    );
  });

  Future<void> frames(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/settings/sync', routes: [
      GoRoute(path: '/settings/sync', builder: (_, _) => const SyncScreen()),
      GoRoute(path: '/settings/sync/review', builder: (_, _) => const SyncReviewScreen()),
      GoRoute(
        path: '/settings/sync/wifi',
        builder: (_, state) => WifiSyncScreen(
          show: state.uri.queryParameters['mode'] == 'show',
          code: state.uri.queryParameters['code'],
        ),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        householdSyncProvider.overrideWithValue(sync),
        secureKeyStoreProvider.overrideWithValue(keys),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await frames(tester);
  }

  Future<void> tidy(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(db.close);
  }

  testWidgets('off: start or join, the project relay shown but not available', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Start syncing from this phone'), findsOneWidget);
    expect(find.text('Join a phone that already syncs'), findsOneWidget);
    expect(find.text('Not available yet.'), findsOneWidget);
    final project = tester.widget<RadioListTile<RelayChoice>>(
        find.widgetWithText(RadioListTile<RelayChoice>, 'OpenHearth relay'));
    expect(project.enabled, isFalse);

    // A name and a private address are required, in plain words.
    await tester.enterText(find.byKey(const Key('sync-relay')), 'http://relay.example.org');
    await tester.tap(find.byKey(const Key('sync-start')));
    await frames(tester);
    expect(find.text('Give this phone a name, like “Phone 2”.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('sync-label')), 'Mei’s phone');
    await tester.tap(find.byKey(const Key('sync-start')));
    await frames(tester);
    expect(find.text('The address must start with https:// so the connection is private.'),
        findsOneWidget);
    expect(bridgeLoads, 0, reason: 'nothing loads until sync really starts');
    await tidy(tester);
  });

  testWidgets('on: status in plain words, waiting count, review items', (tester) async {
    await pumpScreen(tester);
    sync.snapshot.value = SyncSnapshot(
      mode: SyncMode.on,
      settings: SyncSettings(
          on: true, relay: Uri.parse('https://relay.example.org/'), label: 'Mei’s phone'),
      lastSynced: DateTime.now(),
      waiting: 2,
      review: [
        ReviewItem(
          key: Uint8List(1),
          kind: 'field',
          op: Uint8List(32),
          opKind: 'put',
          table: 'feeding_logs',
          row: 'f1',
          field: 'amount_ml',
          mine: '120.0',
          current: '90.0',
        ),
      ],
      devices: [
        HouseholdDevice(Uint8List(32), 'Mei’s phone', forgotten: false, me: true),
        HouseholdDevice(Uint8List.fromList(List.filled(32, 1)), 'Jordan’s phone',
            forgotten: false, me: false),
      ],
    );
    await frames(tester);
    expect(find.text('Syncing as Mei’s phone'), findsOneWidget);
    expect(find.textContaining('Last synced'), findsOneWidget);
    expect(find.text('2 changes waiting to send.'), findsOneWidget);
    expect(find.text('Jordan’s phone'), findsOneWidget);
    expect(find.text('Forget this phone'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sync-review')));
    await frames(tester);
    expect(find.text('Feed: amount ml'), findsOneWidget);
    expect(find.text('Your change (120) was replaced by 90 from another phone.'), findsOneWidget);
    expect(find.text('Use mine'), findsOneWidget);
    expect(find.text('Keep theirs'), findsOneWidget);
    await tidy(tester);
  });

  testWidgets('forget is phrase-protected: wrong words change nothing', (tester) async {
    await keys.writeMnemonic(words);
    await pumpScreen(tester);
    sync.snapshot.value = SyncSnapshot(
      mode: SyncMode.on,
      settings: const SyncSettings(on: true, label: 'Mei’s phone'),
      devices: [HouseholdDevice(Uint8List(32), 'Mei’s phone', forgotten: false, me: true)],
    );
    await frames(tester);
    expect(find.text('No relay: sync with a phone on this Wi-Fi below.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('sync-forget-self')));
    await tester.tap(find.byKey(const Key('sync-forget-self')));
    await frames(tester);
    await tester.enterText(find.byType(TextField).last, otherWords);
    await frames(tester);
    await tester.tap(find.text('Continue'));
    await frames(tester);
    expect(find.text('Those words don’t match this household’s. Nothing was changed.'),
        findsOneWidget);
    expect(await tester.runAsync(keys.readMnemonic), words);
    expect(sync.snapshot.value.mode, SyncMode.on);
    await tidy(tester);
  });

  testWidgets('off: no relay is a choice on a phone (same Wi-Fi only)', (tester) async {
    await pumpScreen(tester);
    expect(find.widgetWithText(RadioListTile<RelayChoice>, 'None'), findsOneWidget);
    expect(find.text('Sync only with a phone on the same Wi-Fi.'), findsOneWidget);
    await tidy(tester);
  });

  testWidgets('on: Sync on this Wi-Fi; a typed code with a typo is caught before connecting',
      (tester) async {
    await pumpScreen(tester);
    sync.snapshot.value = SyncSnapshot(
      mode: SyncMode.on,
      settings: const SyncSettings(on: true, label: 'Mei’s phone'),
      devices: [HouseholdDevice(Uint8List(32), 'Mei’s phone', forgotten: false, me: true)],
    );
    await frames(tester);
    expect(find.text('Sync on this Wi-Fi'), findsOneWidget);
    expect(find.text('Show a code'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('wifi-type')));
    await tester.tap(find.byKey(const Key('wifi-type')));
    await frames(tester);
    await tester.enterText(find.byKey(const Key('wifi-code-field')), 'ABCDEF-GHJKMN-PQRSTV');
    await tester.tap(find.byKey(const Key('wifi-sync')));
    await frames(tester);
    expect(find.text('That code has a typo. Check it against the other phone.'), findsOneWidget);
    await tidy(tester);
  });

  testWidgets('a QR link opens Type a code with the code filled in', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [householdSyncProvider.overrideWithValue(sync)],
      child: const MaterialApp(home: WifiSyncScreen(show: false, code: 'ABCDEF-GHJKMN-PQRSTV')),
    ));
    await frames(tester);
    expect(find.text('ABCDEF-GHJKMN-PQRSTV'), findsOneWidget);
    expect(wifiSyncLink('X'), 'lullaby://sync/settings/sync/wifi?code=X');
    await tidy(tester);
  });
}
