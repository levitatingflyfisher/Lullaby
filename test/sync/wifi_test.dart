// Two Lullaby phones syncing on the same Wi-Fi with no relay (hearthSync ADR
// 0014): one shows a code, the other types it. Each phone is the real data
// layer; the "Wi-Fi" is a real HTTP socket on loopback. See relay_harness.dart
// for what must be built first (only the bridge: no relay runs here).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hearth_sync/hearth_sync.dart' show LanCode;
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/sync/data/household_sync.dart';
import 'package:lullaby/features/sync/presentation/sync_words.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';

import '../test_setup.dart';
import 'relay_harness.dart';

void main() {
  ensureSqlite3();
  late Phone mei, jordan;

  setUp(() {
    HttpOverrides.global = null;
    mei = Phone('Mei');
    jordan = Phone('Jordan');
  });

  tearDown(() async {
    await mei.close();
    await jordan.close();
  });

  final t0 = DateTime(2026, 10, 2, 3, 10);
  final june = BabyEntity(
    id: 'june',
    name: 'June',
    dateOfBirth: DateTime(2026, 8, 20),
    createdAt: t0,
    modifiedAt: t0,
  );
  FeedingLogEntity bottle(String id) => FeedingLogEntity(
        id: id,
        babyId: 'june',
        type: FeedingType.bottle,
        startTime: t0,
        amountMl: 90,
        createdAt: t0,
        modifiedAt: t0,
      );

  Future<List<FeedingLogEntity>> feedsOn(Phone p) async =>
      ((await p.feeds.getAllForBaby('june')) as Success<List<FeedingLogEntity>>).value;

  /// [shows] shows a code; [types] types it. Both end synced.
  Future<void> wifi(Phone shows, Phone types) async {
    final listener = await shows.sync.listenOnWifi(advertise: '127.0.0.1');
    await types.sync.syncOnWifi(LanCode.tryParse(listener.code.text)!);
    await listener.done;
    await pumpEventQueue();
  }

  /// Both phones have sync on with the same words, and [relay] (none by default).
  Future<void> pair({Uri? relay}) async {
    mei.words = householdWords;
    await mei.babies.createBaby(june);
    await mei.feeds.createFeeding(bottle('before-sync'));
    await mei.sync.turnOn(label: 'Mei’s phone', relay: relay);
    jordan.words = householdWords;
    await jordan.sync.turnOn(label: 'Jordan’s phone', relay: relay);
    await wifi(mei, jordan);
  }

  test('with no relay, a feed and a note cross on the same Wi-Fi, both ways',
      timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    expect((await feedsOn(jordan)).map((f) => f.id), ['before-sync']);
    expect((await jordan.db.babyDao.getAllBabies()).single.name, 'June');

    await jordan.notes.add('june', 'Fed 90 ml at 3:10.');
    await mei.feeds.createFeeding(bottle('4am'));
    // This time Jordan shows the code.
    await wifi(jordan, mei);
    expect((await mei.notes.watchRecent('june').first).single.author, 'Jordan’s phone');
    expect((await feedsOn(jordan)).map((f) => f.id).toSet(), {'before-sync', '4am'});

    for (final p in [mei, jordan]) {
      final s = p.sync.snapshot.value;
      expect(s.lastPath, SyncPath.wifi, reason: p.name);
      expect(s.lastSynced, isNotNull, reason: p.name);
      expect(syncHeadline(s, DateTime.now()), startsWith('Last synced'), reason: p.name);
      expect(syncHeadline(s, DateTime.now()), endsWith('on this Wi-Fi.'), reason: p.name);
      // Ops learned on the Wi-Fi wait in the relay outbox; with no relay that
      // is not "waiting", so the line is not shown.
      expect(syncWaitingLine(s), isNull, reason: p.name);
    }
  });

  test('with a relay set but unreachable, the Wi-Fi still syncs',
      timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair(relay: Uri.parse('http://127.0.0.1:9/'));
    expect((await feedsOn(jordan)).map((f) => f.id), ['before-sync']);
    expect(jordan.sync.snapshot.value.lastPath, SyncPath.wifi);
  });


  test('a cold start straight into a Wi-Fi screen waits for the log, not "turn sync on"',
      timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    await mei.feeds.createFeeding(bottle('cold'));
    await mei.restart(boot: false);
    await jordan.restart(boot: false);
    await wifi(mei, jordan);
    expect((await feedsOn(jordan)).map((f) => f.id).toSet(), {'before-sync', 'cold'});
  });
}
