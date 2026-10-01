// Shared by the two-phone tests: the real hearthSync relay binary on
// localhost, and Lullaby "phones" built from the real data layer. They need
// the host build of the kernel bridge and the relay (see AGENTS.md):
//   (cd ../hearthSync/flutter/hearth_sync/rust && CARGO_TARGET_DIR=$PWD/target cargo build --release)
//   (cd ../hearthSync && CARGO_TARGET_DIR=$PWD/target cargo build --release -p hearth_sync_relay)
// or point HEARTH_SYNC_LIB / HEARTH_RUST_RELAY at them. A missing build fails
// the test rather than skipping it.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:lullaby/features/babies/data/repositories/baby_repository_impl.dart';
import 'package:lullaby/features/handoff/data/handoff_repository_impl.dart';
import 'package:lullaby/features/sync/data/household_sync.dart';
import 'package:lullaby/features/sync/data/sync_settings_store.dart';
import 'package:lullaby/features/tracking/data/repositories/feeding_repository_impl.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/testing.dart';

final hearthRepo = Directory('${Directory.current.path}/../hearthSync').absolute.path;

final bridgeLib = Platform.environment['HEARTH_SYNC_LIB'] ??
    '$hearthRepo/flutter/hearth_sync/rust/target/release/libhearth_sync_bridge.so';
final relayBin =
    Platform.environment['HEARTH_RUST_RELAY'] ?? '$hearthRepo/target/release/hearth-relay';

/// Scratch for the relay's store: never the repo, never bare /tmp.
final relayScratch = Platform.environment['LULLABY_SYNC_SCRATCH'] ??
    '${Directory.current.path}/build/sync-relay-test';

Future<void> initBridge() async {
  expect(File(bridgeLib).existsSync(), isTrue, reason: 'build the bridge first: $bridgeLib');
  await HearthSync.init(library: ExternalLibrary.open(bridgeLib));
}

/// A valid BIP39 phrase: the household's 12 words.
const householdWords =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

/// The relay binary on a free localhost port.
class RelayProcess {
  RelayProcess(this.dir);

  final Directory dir;
  late Process _p;
  int port = 0;
  final lines = <String>[];

  Uri get uri => Uri.parse('http://127.0.0.1:$port/');

  static Future<RelayProcess> launch(String name) async {
    expect(File(relayBin).existsSync(), isTrue, reason: 'build the relay first: $relayBin');
    final dir = Directory('$relayScratch/$name');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final r = RelayProcess(dir);
    await r._start();
    return r;
  }

  Future<void> _start() async {
    final started = Completer<void>();
    _p = await Process.start(relayBin, [
      '--data', dir.path,
      '--listen', '127.0.0.1:0',
      '--max-reader-nonces', '100000',
    ]);
    _p.stdout.drain<void>();
    _p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
      lines.add(l);
      try {
        final j = jsonDecode(l);
        if (j is Map && j['event'] == 'start' && !started.isCompleted) {
          port = int.parse((j['listen'] as String).split(':').last);
          started.complete();
        }
      } on FormatException {
        // not JSON
      }
    });
    await started.future.timeout(const Duration(seconds: 20),
        onTimeout: () => throw StateError('relay did not start: $lines'));
  }

  Future<void> stop() async {
    _p.kill(ProcessSignal.sigterm);
    await _p.exitCode.timeout(const Duration(seconds: 20), onTimeout: () {
      _p.kill(ProcessSignal.sigkill);
      return _p.exitCode;
    });
  }
}

/// One phone: its own database, settings, device key and repositories, all
/// the real Lullaby data layer.
class Phone {
  Phone(this.name) {
    // Two phones means two databases in one test, on purpose.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final rng = Random.secure();
    _key = List.generate(32, (_) => rng.nextInt(256));
    _build();
  }

  void _build() {
    sync = HouseholdSync(
      db: db,
      settingsStore: SyncSettingsStore(settings),
      readWords: () async => words,
      deriveSeed: OpenHearthMnemonic.deriveSeed,
      signer: () => SoftwareSigner.fromSeed(_key),
      initBridge: initBridge,
      forgetWords: () async => words = null,
      // Rounds run when a test asks, not on timers.
      loop: (hs, relay) => SyncLoop(hs, relay, interval: const Duration(days: 1)),
    );
    writer = HouseholdRecordWriter(sync);
    babies = BabyRepositoryImpl(db.babyDao, writer);
    feeds = FeedingRepositoryImpl(db.feedingDao, writer);
    notes = HandoffRepositoryImpl(db, writer);
  }

  final String name;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final settings = InMemorySecretStorage();
  late final List<int> _key;
  String? words;
  late HouseholdSync sync;
  late HouseholdRecordWriter writer;
  late BabyRepositoryImpl babies;
  late FeedingRepositoryImpl feeds;
  late HandoffRepositoryImpl notes;

  /// The app restarts: same database, settings, words and device key. With
  /// [boot] false nothing has asked for the log yet (a cold start straight
  /// into a screen, as a QR link does).
  Future<void> restart({bool boot = true}) async {
    await sync.close();
    _build();
    if (boot) await sync.boot();
  }

  /// One full round with the relay; fails the test if it did not finish.
  Future<void> syncNow() async {
    final s = await sync.syncNow();
    expect(s, isNotNull, reason: '$name has no relay');
    expect(s!.ok, isTrue, reason: '$name: ${s.error}');
  }

  Future<void> close() async {
    await sync.close();
    await db.close();
  }
}
