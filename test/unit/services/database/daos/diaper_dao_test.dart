import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:lullaby/services/database/daos/diaper_dao.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late DiaperDao dao;
  final now = DateTime(2025, 6, 15, 14, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.diaperDao;
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  DiaperLogsCompanion makeDiaper({
    String id = 'd1',
    DateTime? time,
    String type = 'wet',
  }) =>
      DiaperLogsCompanion.insert(
        id: id,
        babyId: 'baby1',
        time: time ?? now,
        type: type,
        createdAt: now,
        modifiedAt: now,
      );

  group('DiaperDao', () {
    test('insert and getAll', () async {
      await dao.insertDiaper(makeDiaper());
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, hasLength(1));
      expect(logs.first.type, 'wet');
    });

    test('multiple inserts', () async {
      await dao.insertDiaper(makeDiaper(id: 'd1'));
      await dao.insertDiaper(makeDiaper(id: 'd2', type: 'dirty'));
      await dao.insertDiaper(makeDiaper(id: 'd3', type: 'both'));
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, hasLength(3));
    });

    test('countInRange counts correctly', () async {
      final dayStart = DateTime(2025, 6, 15);
      final dayEnd = DateTime(2025, 6, 16);
      await dao.insertDiaper(makeDiaper(id: 'd1', time: now));
      await dao.insertDiaper(makeDiaper(id: 'd2', time: now));
      await dao.insertDiaper(makeDiaper(
          id: 'd3',
          time: now.subtract(const Duration(days: 2))));

      final count = await dao.countInRange('baby1', dayStart, dayEnd);
      expect(count, 2);
    });

    test('countByTypeInRange filters by type', () async {
      final dayStart = DateTime(2025, 6, 15);
      final dayEnd = DateTime(2025, 6, 16);
      await dao.insertDiaper(makeDiaper(id: 'd1', type: 'wet'));
      await dao.insertDiaper(makeDiaper(id: 'd2', type: 'dirty'));
      await dao.insertDiaper(makeDiaper(id: 'd3', type: 'wet'));

      final wetCount =
          await dao.countByTypeInRange('baby1', 'wet', dayStart, dayEnd);
      expect(wetCount, 2);

      final dirtyCount =
          await dao.countByTypeInRange('baby1', 'dirty', dayStart, dayEnd);
      expect(dirtyCount, 1);
    });

    test('getInRange returns only logs in range', () async {
      final dayStart = DateTime(2025, 6, 15);
      final dayEnd = DateTime(2025, 6, 16);
      await dao.insertDiaper(makeDiaper(id: 'd1', time: now));
      await dao.insertDiaper(makeDiaper(
          id: 'd2',
          time: now.subtract(const Duration(days: 2))));

      final logs = await dao.getInRange('baby1', dayStart, dayEnd);
      expect(logs, hasLength(1));
      expect(logs.first.id, 'd1');
    });

    test('updateDiaper modifies entry', () async {
      await dao.insertDiaper(makeDiaper());
      final updated = DiaperLogsCompanion(
        id: const Value('d1'),
        babyId: const Value('baby1'),
        time: Value(now),
        type: const Value('dirty'),
        color: const Value('yellow'),
        createdAt: Value(now),
        modifiedAt: Value(now),
      );
      await dao.updateDiaper(updated);
      final logs = await dao.getAllForBaby('baby1');
      expect(logs.first.type, 'dirty');
      expect(logs.first.color, 'yellow');
    });

    test('deleteDiaper removes entry', () async {
      await dao.insertDiaper(makeDiaper());
      await dao.deleteDiaper('d1');
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, isEmpty);
    });

    test('watchAllForBaby emits updates', () async {
      final stream = dao.watchAllForBaby('baby1');
      expect(await stream.first, isEmpty);
    });
  });
}
