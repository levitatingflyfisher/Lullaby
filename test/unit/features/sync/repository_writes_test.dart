import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/data/repositories/baby_repository_impl.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/sync/data/lullaby_records.dart';
import 'package:lullaby/features/sync/data/record_projection.dart';
import 'package:lullaby/features/sync/data/record_writer.dart';
import 'package:lullaby/features/tracking/data/repositories/feeding_repository_impl.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../test_setup.dart';

/// Writes through to Drift like the direct path, and records what it was
/// asked to send, as the kernel path would put it in the log.
class RecordingWriter extends DirectRecordWriter {
  RecordingWriter(super.projection);
  final sent = <(String, String, Map<String, Object?>)>[];
  final restored = <(String, String)>[];
  final deleted = <(String, String)>[];

  @override
  Future<void> send(RecordTable table, String id, Map<String, Object?> fields) {
    sent.add((table.name, id, fields));
    return super.send(table, id, fields);
  }

  @override
  Future<void> delete(RecordTable table, String id) {
    deleted.add((table.name, id));
    return super.delete(table, id);
  }

  @override
  Future<void> restore(RecordTable table, String id, Map<String, Object?> fields) {
    restored.add((table.name, id));
    return super.restore(table, id, fields);
  }
}

void main() {
  ensureSqlite3();
  late AppDatabase db;
  late RecordingWriter writer;
  final t0 = DateTime(2026, 10, 1, 3, 10);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    writer = RecordingWriter(RecordProjection(db));
    await BabyRepositoryImpl(db.babyDao, writer).createBaby(BabyEntity(
      id: 'b1',
      name: 'June',
      dateOfBirth: DateTime(2026, 8, 20),
      createdAt: t0,
      modifiedAt: t0,
    ));
    writer.sent.clear();
  });
  tearDown(() => db.close());

  FeedingLogEntity bottle() => FeedingLogEntity(
        id: 'f1',
        babyId: 'b1',
        type: FeedingType.bottle,
        startTime: t0,
        amountMl: 90,
        createdAt: t0,
        modifiedAt: t0,
      );

  test('creating a baby sends its synced fields, never the local ones', () async {
    final b = (await db.babyDao.getAllBabies()).single;
    expect(b.isActive, isTrue);
    await BabyRepositoryImpl(db.babyDao, writer).createBaby(BabyEntity(
      id: 'b2',
      name: 'Ada',
      dateOfBirth: DateTime(2026, 8, 20),
      photoPath: '/photos/ada.jpg',
      createdAt: t0,
      modifiedAt: t0,
    ));
    final fields = writer.sent.single.$3;
    expect(fields.keys, isNot(contains('is_active')));
    expect(fields.keys, isNot(contains('photo_path')));
    // The new baby is the selected one, and its photo stays on this phone.
    final b2 = await db.babyDao.getBabyById('b2');
    expect(b2!.isActive, isTrue);
    expect(b2.photoPath, '/photos/ada.jpg');
  });

  test('an update sends only the fields that changed', () async {
    final repo = FeedingRepositoryImpl(db.feedingDao, writer);
    await repo.createFeeding(bottle());
    writer.sent.clear();
    final later = t0.add(const Duration(minutes: 5));
    await repo.updateFeeding(bottle().copyWith(amountMl: () => 120, modifiedAt: later));
    expect(writer.sent.single.$3, {
      'amount_ml': '120.0',
      'modified_at': later.millisecondsSinceEpoch ~/ 1000,
    });
  });

  test('saving with nothing changed sends nothing', () async {
    final repo = FeedingRepositoryImpl(db.feedingDao, writer);
    await repo.createFeeding(bottle());
    writer.sent.clear();
    await repo.updateFeeding(bottle().copyWith(modifiedAt: t0.add(const Duration(minutes: 1))));
    expect(writer.sent, isEmpty);
  });

  test('a notes edit sends only notes', () async {
    final repo = FeedingRepositoryImpl(db.feedingDao, writer);
    await repo.createFeeding(bottle());
    writer.sent.clear();
    await repo.updateNotes('f1', 'spit up a little');
    expect(writer.sent.single.$3.keys, unorderedEquals(['notes', 'modified_at']));
  });

  test('Undo after a delete is a restore, not a fresh create', () async {
    final repo = FeedingRepositoryImpl(db.feedingDao, writer);
    await repo.createFeeding(bottle());
    await repo.deleteFeeding('f1');
    expect(writer.deleted, [('feeding_logs', 'f1')]);
    writer.sent.clear();
    await repo.restoreFeeding(bottle());
    expect(writer.restored, [('feeding_logs', 'f1')]);
    expect(await db.feedingDao.getAllForBaby('b1'), hasLength(1));
  });

  test('deleting the selected baby selects another one', () async {
    final repo = BabyRepositoryImpl(db.babyDao, writer);
    await repo.createBaby(BabyEntity(
        id: 'b2', name: 'Ada', dateOfBirth: t0, createdAt: t0, modifiedAt: t0));
    await FeedingRepositoryImpl(db.feedingDao, writer)
        .createFeeding(bottle().copyWith(babyId: 'b2'));
    await repo.deleteBaby('b2');
    final left = await db.babyDao.getAllBabies();
    expect(left.single.id, 'b1');
    expect(left.single.isActive, isTrue);
    expect(await db.feedingDao.getAllForBaby('b2'), isEmpty);
  });
}
