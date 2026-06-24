import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:lullaby/services/database/daos/feeding_dao.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late FeedingDao dao;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.feedingDao;
    // Insert a baby first
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  FeedingLogsCompanion makeFeeding({
    String id = 'f1',
    DateTime? startTime,
    String type = 'breast',
  }) =>
      FeedingLogsCompanion.insert(
        id: id,
        babyId: 'baby1',
        type: type,
        startTime: startTime ?? now,
        createdAt: now,
        modifiedAt: now,
      );

  group('FeedingDao', () {
    test('insert and getAll', () async {
      await dao.insertFeeding(makeFeeding());
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, hasLength(1));
      expect(logs.first.type, 'breast');
    });

    test('getLastFeeding returns most recent', () async {
      await dao.insertFeeding(makeFeeding(
          id: 'f1', startTime: now.subtract(const Duration(hours: 2))));
      await dao.insertFeeding(
          makeFeeding(id: 'f2', startTime: now));

      final last = await dao.getLastFeeding('baby1');
      expect(last, isNotNull);
      expect(last!.id, 'f2');
    });

    test('getInRange returns only logs in range', () async {
      await dao.insertFeeding(makeFeeding(
          id: 'f1', startTime: now.subtract(const Duration(days: 2))));
      await dao.insertFeeding(
          makeFeeding(id: 'f2', startTime: now));

      final start = now.subtract(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 1));
      final logs = await dao.getInRange('baby1', start, end);
      expect(logs, hasLength(1));
      expect(logs.first.id, 'f2');
    });

    test('updateFeeding modifies entry', () async {
      await dao.insertFeeding(makeFeeding());
      final updated = FeedingLogsCompanion(
        id: const Value('f1'),
        babyId: const Value('baby1'),
        type: const Value('bottle'),
        startTime: Value(now),
        amountMl: const Value(120.0),
        createdAt: Value(now),
        modifiedAt: Value(now),
      );
      await dao.updateFeeding(updated);
      final logs = await dao.getAllForBaby('baby1');
      expect(logs.first.type, 'bottle');
      expect(logs.first.amountMl, 120.0);
    });

    test('deleteFeeding removes entry', () async {
      await dao.insertFeeding(makeFeeding());
      await dao.deleteFeeding('f1');
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, isEmpty);
    });

    test('getLastFeeding returns null when no logs', () async {
      final last = await dao.getLastFeeding('baby1');
      expect(last, isNull);
    });

    test('watchLastFeeding emits null then value', () async {
      final stream = dao.watchLastFeeding('baby1');
      expect(await stream.first, isNull);
    });

    test('getActiveBreastFeeding returns null when none exist', () async {
      final active = await dao.getActiveBreastFeeding('baby1');
      expect(active, isNull);
    });

    test('getActiveBreastFeeding returns in-progress breast feed', () async {
      await dao.insertFeeding(makeFeeding(id: 'f1'));
      final active = await dao.getActiveBreastFeeding('baby1');
      expect(active, isNotNull);
      expect(active!.id, 'f1');
    });

    test('getActiveBreastFeeding ignores ended breast feeds', () async {
      await dao.insertFeeding(FeedingLogsCompanion.insert(
        id: 'f1',
        babyId: 'baby1',
        type: 'breast',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: Value(now),
        durationMinutes: const Value(30),
        createdAt: now,
        modifiedAt: now,
      ));
      final active = await dao.getActiveBreastFeeding('baby1');
      expect(active, isNull);
    });

    test('getActiveBreastFeeding ignores bottle/solid feeds', () async {
      await dao.insertFeeding(makeFeeding(id: 'f1', type: 'bottle'));
      await dao.insertFeeding(makeFeeding(id: 'f2', type: 'solid'));
      final active = await dao.getActiveBreastFeeding('baby1');
      expect(active, isNull);
    });
  });
}
