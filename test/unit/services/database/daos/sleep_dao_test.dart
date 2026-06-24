import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:lullaby/services/database/daos/sleep_dao.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late SleepDao dao;
  final now = DateTime(2025, 6, 15, 22, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.sleepDao;
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  SleepLogsCompanion makeSleep({
    String id = 's1',
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      SleepLogsCompanion.insert(
        id: id,
        babyId: 'baby1',
        startTime: startTime ?? now,
        type: 'nap',
        createdAt: now,
        modifiedAt: now,
      );

  group('SleepDao', () {
    test('insert and getAll', () async {
      await dao.insertSleep(makeSleep());
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, hasLength(1));
      expect(logs.first.type, 'nap');
    });

    test('getActiveSleep returns ongoing sleep', () async {
      await dao.insertSleep(makeSleep());
      final active = await dao.getActiveSleep('baby1');
      expect(active, isNotNull);
      expect(active!.endTime, isNull);
    });

    test('getActiveSleep returns null when all completed', () async {
      await dao.insertSleep(makeSleep());
      // Complete the sleep
      final updated = SleepLogsCompanion(
        id: const Value('s1'),
        babyId: const Value('baby1'),
        startTime: Value(now),
        endTime: Value(now.add(const Duration(hours: 1))),
        durationMinutes: const Value(60),
        type: const Value('nap'),
        createdAt: Value(now),
        modifiedAt: Value(now),
      );
      await dao.updateSleep(updated);
      final active = await dao.getActiveSleep('baby1');
      expect(active, isNull);
    });

    test('getInRange returns only logs in range', () async {
      await dao.insertSleep(makeSleep(
          id: 's1', startTime: now.subtract(const Duration(days: 2))));
      await dao.insertSleep(makeSleep(id: 's2', startTime: now));

      final start = now.subtract(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 1));
      final logs = await dao.getInRange('baby1', start, end);
      expect(logs, hasLength(1));
      expect(logs.first.id, 's2');
    });

    test('deleteSleep removes entry', () async {
      await dao.insertSleep(makeSleep());
      await dao.deleteSleep('s1');
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, isEmpty);
    });

    test('watchActiveSleep emits updates', () async {
      final stream = dao.watchActiveSleep('baby1');
      expect(await stream.first, isNull);
    });
  });
}
