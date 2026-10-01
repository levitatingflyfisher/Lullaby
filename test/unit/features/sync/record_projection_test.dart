import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:lullaby/features/sync/data/lullaby_records.dart';
import 'package:lullaby/features/sync/data/record_projection.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../test_setup.dart';

// The projection writes Lullaby's Drift tables from the kernel's changes. It
// runs inside the kernel's own transaction, so it must never throw on input
// the kernel can legally produce (hearth_sync README: a throw there leaves the
// kernel ahead of the store).

final t0 = DateTime(2026, 10, 1, 3, 10);
int secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

RowUpdate baby(String id, {String name = 'June', bool visible = true}) =>
    RowUpdate('babies', id, visible, visible
        ? {
            'name': name,
            'date_of_birth': secs(DateTime(2026, 8, 20)),
            'gender': 'female',
            'created_at': secs(t0),
            'modified_at': secs(t0),
          }
        : const {});

RowUpdate feed(String id, String babyId, {bool visible = true, String? notes}) =>
    RowUpdate('feeding_logs', id, visible, visible
        ? {
            'baby_id': babyId,
            'type': 'bottle',
            'start_time': secs(t0),
            'end_time': null,
            'duration_minutes': null,
            'side': null,
            'amount_ml': '90.0',
            'amount_oz': null,
            'notes': notes,
            'created_at': secs(t0),
            'modified_at': secs(t0),
          }
        : const {});

StreamUpdate note(int n, String babyId, String text, {bool present = true}) =>
    StreamUpdate(
      stream: handoffStream,
      id: Uint8List.fromList(List.filled(32, n)),
      millis: t0.millisecondsSinceEpoch,
      counter: 0,
      device: Uint8List(32),
      record: jsonEncode({'baby': babyId, 'text': text, 'by': 'Mei', 'at': secs(t0)}),
      present: present,
    );

void main() {
  ensureSqlite3();
  late AppDatabase db;
  late RecordProjection projection;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    projection = RecordProjection(db);
  });
  tearDown(() => db.close());

  Future<void> apply(Changes c) => db.transaction(() => projection.apply(c));

  test('a baby and its feed land in Drift with real types', () async {
    await apply(Changes(rows: [baby('b1'), feed('f1', 'b1', notes: 'spit up')]));
    final f = (await db.feedingDao.getAllForBaby('b1')).single;
    expect(f.amountMl, 90.0);
    expect(f.startTime, DateTime.fromMillisecondsSinceEpoch(secs(t0) * 1000));
    expect(f.notes, 'spit up');
    final b = (await db.babyDao.getAllBabies()).single;
    expect(b.name, 'June');
    // The only baby on this phone becomes the selected one.
    expect(b.isActive, isTrue);
  });

  test('children listed before their baby still land (parents first)', () async {
    await apply(Changes(rows: [feed('f1', 'b1'), baby('b1')]));
    expect(await db.feedingDao.getAllForBaby('b1'), hasLength(1));
  });

  test('a feed whose baby is not here yet is parked, then lands with it',
      () async {
    await apply(Changes(rows: [feed('f1', 'b1')]));
    expect(await db.feedingDao.getAllForBaby('b1'), isEmpty);
    await apply(Changes(rows: [baby('b1')]));
    expect(await db.feedingDao.getAllForBaby('b1'), hasLength(1));
  });

  test('hiding a baby removes its records first, so the foreign key holds',
      () async {
    await apply(Changes(rows: [baby('b1'), feed('f1', 'b1')]));
    // The kernel may list the baby's hide before (or without) its children.
    await apply(Changes(rows: [baby('b1', visible: false)]));
    expect(await db.babyDao.getAllBabies(), isEmpty);
    expect(await db.feedingDao.getAllForBaby('b1'), isEmpty);
  });

  test('an update never clears which baby this phone has selected', () async {
    await apply(Changes(rows: [baby('b1'), baby('b2', name: 'Ada')]));
    await db.babyDao.setActiveBaby('b2');
    await apply(Changes(rows: [baby('b2', name: 'Ada Lovelace')]));
    final b2 = await db.babyDao.getBabyById('b2');
    expect(b2!.name, 'Ada Lovelace');
    expect(b2.isActive, isTrue);
  });

  test('replaceView keeps the local selection and photo', () async {
    await apply(Changes(rows: [baby('b1'), baby('b2', name: 'Ada')]));
    await db.babyDao.setActiveBaby('b2');
    await db.customStatement(
        "UPDATE babies SET photo_path = '/photos/ada.jpg' WHERE id = 'b2'");
    await apply(Changes(
        replaceView: true, rows: [baby('b1'), baby('b2', name: 'Ada')]));
    final b2 = await db.babyDao.getBabyById('b2');
    expect(b2!.isActive, isTrue);
    expect(b2.photoPath, '/photos/ada.jpg');
  });

  test('handoff notes arrive and leave with the stream', () async {
    await apply(Changes(rows: [baby('b1')], streams: [note(1, 'b1', 'left side')]));
    var notes = await db.select(db.handoffNotes).get();
    expect(notes.single.body, 'left side');
    expect(notes.single.author, 'Mei');
    await apply(Changes(streams: [note(1, 'b1', 'left side', present: false)]));
    notes = await db.select(db.handoffNotes).get();
    expect(notes, isEmpty);
  });

  test('readRow gives a row back in its log encoding', () async {
    await apply(Changes(rows: [baby('b1'), feed('f1', 'b1')]));
    final row = await projection.readRow(feedingSpec, 'f1');
    expect(row, feed('f1', 'b1').fields);
  });

  test('a row for a table this version does not know is ignored', () async {
    await apply(Changes(rows: [
      const RowUpdate('bath_logs', 'x', true, {'temp': 37}),
    ]));
  });
}
