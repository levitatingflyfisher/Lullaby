import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:lullaby/features/sync/data/household_sync.dart';
import 'package:lullaby/features/sync/data/record_writer.dart';
import 'package:lullaby/features/sync/data/sync_settings_store.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:sanctuary_backup_ui/testing.dart';

import '../../../test_setup.dart';

// The checked claim behind "sync is off until a parent turns it on": with sync
// off, the kernel bridge is never loaded and no relay client is ever made, so
// nothing can leave the phone.

/// The off path must not even read the settings (a platform call).
class ThrowingStorage extends InMemorySecretStorage {
  @override
  Future<String?> read(String key) => throw StateError('read settings while off');
}

void main() {
  ensureSqlite3();
  late AppDatabase db;
  var bridgeLoads = 0, relayClients = 0;

  HouseholdSync make(InMemorySecretStorage settings) => HouseholdSync(
        db: db,
        settingsStore: SyncSettingsStore(settings),
        readWords: () async => null,
        deriveSeed: (_) => throw StateError('no seed while off'),
        signer: () => throw StateError('no device key while off'),
        initBridge: () async => bridgeLoads++,
        forgetWords: () async {},
        relayClient: (uri) {
          relayClients++;
          return RelayClient(uri);
        },
      );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bridgeLoads = relayClients = 0;
  });
  tearDown(() => db.close());

  test('a fresh install writes straight to Drift and loads nothing', () async {
    final sync = make(ThrowingStorage());
    final writer = await sync.writer();
    expect(writer, isA<DirectRecordWriter>());
    expect(sync.snapshot.value.mode, SyncMode.off);
    expect(bridgeLoads, 0);
    expect(relayClients, 0);
  });

  test('with sync off, no Wi-Fi code can be shown or used: no port opens', () async {
    final sync = make(ThrowingStorage());
    await expectLater(sync.listenOnWifi(advertise: '127.0.0.1'), throwsA(isA<StateError>()));
    final code = LanCode('192.168.1.2', 4000, Uint8List.fromList([1, 2, 3, 4]));
    await expectLater(sync.syncOnWifi(code), throwsA(isA<StateError>()));
    expect(bridgeLoads, 0);
  });

  test('turning sync on without the 12 words is refused, and loads nothing', () async {
    final sync = make(InMemorySecretStorage());
    await expectLater(
      sync.turnOn(label: 'Mei’s phone', relay: Uri.parse('https://relay.example/')),
      throwsA(isA<NoRecoveryWordsException>()),
    );
    expect(bridgeLoads, 0);
    expect(relayClients, 0);
  });

  test('sync left on but the words removed: records stay local, nothing loads', () async {
    final settings = InMemorySecretStorage();
    await SyncSettingsStore(settings).write(const SyncSettings(on: true, label: 'Mei’s phone'));
    // A household log is on this phone (sync was turned on before).
    await db.customStatement('CREATE TABLE hearth_records (key BLOB PRIMARY KEY, value BLOB)');
    await db.customStatement("INSERT INTO hearth_records VALUES (x'01', x'02')");
    final sync = make(settings);
    expect(await sync.writer(), isA<DirectRecordWriter>());
    expect(sync.snapshot.value.mode, SyncMode.needsWords);
    expect(bridgeLoads, 0);
  });

  group('relay address', () {
    test('https is fine; http only to this computer or the emulator host', () {
      expect(relayAddressProblem('https://relay.example.org'), isNull);
      expect(relayAddressProblem('http://10.0.2.2:18081/'), isNull);
      expect(relayAddressProblem('http://relay.example.org'), contains('https://'));
      expect(relayAddressProblem(''), isNotNull);
      expect(relayAddressProblem('relay'), isNotNull);
      expect(relayUri('https://relay.example.org/hs').path, '/hs/');
    });
  });
}
