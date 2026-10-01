// Two Lullaby phones syncing only through the real hearthSync relay binary,
// over real HTTP on localhost. Each phone is the real data layer (Drift,
// repositories, HouseholdSync, the kernel bridge). See relay_harness.dart for
// what must be built first.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/sync/data/household_sync.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';

import '../test_setup.dart';
import 'relay_harness.dart';

void main() {
  ensureSqlite3();
  late RelayProcess relay;
  late Phone mei, jordan;

  setUp(() async {
    // flutter_test_config's binding answers every HTTP request with 400; these
    // tests need the real network stack to reach the relay on localhost.
    HttpOverrides.global = null;
    relay = await RelayProcess.launch('two-phones');
    mei = Phone('Mei');
    jordan = Phone('Jordan');
  });

  tearDown(() async {
    await mei.close();
    await jordan.close();
    await relay.stop();
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

  /// Mei logged on her own first; then turns sync on; Jordan joins with the
  /// same words. Both have had a round.
  Future<void> pair() async {
    mei.words = householdWords;
    await mei.babies.createBaby(june);
    await mei.feeds.createFeeding(bottle('before-sync'));
    await mei.sync.turnOn(label: 'Mei’s phone', relay: relay.uri);
    expect(mei.sync.snapshot.value.mode, SyncMode.on);
    await mei.syncNow();
    jordan.words = householdWords; // typed on the second phone
    await jordan.sync.turnOn(label: 'Jordan’s phone', relay: relay.uri);
    await jordan.syncNow();
    await mei.syncNow();
  }

  test('a feed logged on one phone appears on the other', timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    // What Mei logged before sync was on reached Jordan too.
    expect((await feedsOn(jordan)).map((f) => f.id), ['before-sync']);
    expect((await jordan.db.babyDao.getAllBabies()).single.name, 'June');

    await mei.feeds.createFeeding(bottle('3am').copyWith(notes: () => 'spit up a little'));
    await mei.syncNow();
    await jordan.syncNow();
    final f = (await feedsOn(jordan)).firstWhere((f) => f.id == '3am');
    expect(f.amountMl, 90);
    expect(f.notes, 'spit up a little');
    expect(f.startTime, t0);
    // Jordan's phone selected the baby it received.
    expect((await jordan.db.babyDao.getAllBabies()).single.isActive, isTrue);
    expect(mei.sync.snapshot.value.waiting, 0);
    expect(mei.sync.snapshot.value.lastSynced, isNotNull);
  });

  test('a handoff note reaches the other phone, signed', timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    await mei.notes.add('june', 'Last feed 3:10, left side. Fussy.');
    await mei.syncNow();
    await jordan.syncNow();
    final notes = await jordan.notes.watchRecent('june').first;
    expect(notes.single.text, 'Last feed 3:10, left side. Fussy.');
    expect(notes.single.author, 'Mei’s phone');
  });

  test('concurrent edits to different fields of one feed both survive', timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    final later = t0.add(const Duration(minutes: 30));
    // Both edit offline, from the same starting record.
    await mei.feeds.updateFeeding(bottle('before-sync').copyWith(notes: () => 'burped twice', modifiedAt: later));
    await jordan.feeds.updateFeeding(bottle('before-sync').copyWith(amountMl: () => 120, modifiedAt: later));
    await mei.syncNow();
    await jordan.syncNow();
    await mei.syncNow();
    for (final p in [mei, jordan]) {
      final f = (await feedsOn(p)).single;
      expect(f.notes, 'burped twice', reason: p.name);
      expect(f.amountMl, 120, reason: p.name);
    }
  });

  test('a delete travels, and its Undo travels after it', timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    final deleted = (await feedsOn(mei)).single;
    await mei.feeds.deleteFeeding(deleted.id);
    await mei.syncNow();
    await jordan.syncNow();
    expect(await feedsOn(jordan), isEmpty);

    await mei.feeds.restoreFeeding(deleted);
    await mei.syncNow();
    await jordan.syncNow();
    expect((await feedsOn(jordan)).single.amountMl, 90);
  });

  test('deleting the baby hides it and its records on the other phone', timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    await mei.babies.deleteBaby('june');
    await mei.syncNow();
    await jordan.syncNow();
    expect(await jordan.db.babyDao.getAllBabies(), isEmpty);
    expect(await feedsOn(jordan), isEmpty);
  });

  test('forget this device: it stops syncing, keeps its records, loses the words', timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    await jordan.sync.forgetThisDevice();
    expect(jordan.words, isNull);
    expect(jordan.sync.snapshot.value.mode, SyncMode.off);
    expect(jordan.sync.snapshot.value.forgotten, isTrue);
    expect(await feedsOn(jordan), hasLength(1), reason: 'no data is recalled');
    // Jordan's later writes stay on Jordan's phone.
    await jordan.feeds.createFeeding(bottle('after-forget'));
    await mei.syncNow();
    expect((await feedsOn(mei)).map((f) => f.id), ['before-sync']);
    final me = mei.sync.snapshot.value.devices.where((d) => d.label == 'Jordan’s phone');
    expect(me.single.forgotten, isTrue);
  });

  test('forgetting another phone wipes it when it next syncs', timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    final jordanKey = mei.sync.snapshot.value.devices.firstWhere((d) => !d.me).device;
    await mei.sync.forgetDevice(jordanKey);
    await mei.syncNow();
    await jordan.sync.syncNow();
    // The round in which Jordan learns it was forgotten wipes it.
    await pumpEventQueue();
    expect(jordan.sync.snapshot.value.forgotten, isTrue);
    expect(jordan.words, isNull);
    expect(jordan.sync.snapshot.value.mode, SyncMode.off);
  });

  // Part A's concern 5: with the words gone while sync is on, a delete went
  // straight to Drift and never reached the log, so the record lived on in
  // the household (and on this phone's next repaint).
  test('a record deleted while the words were missing stays deleted when they return',
      timeout: const Timeout(Duration(minutes: 3)), () async {
    await pair();
    expect(await feedsOn(jordan), hasLength(1));

    final words = mei.words;
    mei.words = null;
    await mei.restart();
    expect(mei.sync.snapshot.value.mode, SyncMode.needsWords);
    await mei.feeds.deleteFeeding('before-sync');
    // A record logged meanwhile still arrives, and an Undo in the gap holds.
    await mei.feeds.createFeeding(bottle('gap'));
    await mei.feeds.deleteFeeding('gap');
    await mei.feeds.restoreFeeding(bottle('gap'));

    mei.words = words;
    await mei.sync.resume();
    expect(mei.sync.snapshot.value.mode, SyncMode.on);
    await mei.syncNow();
    await jordan.syncNow();

    expect((await feedsOn(jordan)).map((f) => f.id), ['gap']);
    expect((await feedsOn(mei)).map((f) => f.id), ['gap']);
    // A restart replays nothing twice.
    await mei.restart();
    await mei.syncNow();
    expect((await feedsOn(mei)).map((f) => f.id), ['gap']);
  });
}
