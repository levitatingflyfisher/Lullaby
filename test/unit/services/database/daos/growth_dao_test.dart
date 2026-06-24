import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:lullaby/services/database/daos/growth_dao.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late GrowthDao dao;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.growthDao;
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  GrowthRecordsCompanion makeRecord({
    String id = 'r1',
    DateTime? measuredAt,
    double? weightKg = 5.5,
  }) =>
      GrowthRecordsCompanion.insert(
        id: id,
        babyId: 'baby1',
        measuredAt: measuredAt ?? now,
        weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
        createdAt: now,
        modifiedAt: now,
      );

  group('GrowthDao', () {
    test('insertGrowthRecord and getAllForBaby', () async {
      await dao.insertGrowthRecord(makeRecord());
      final records = await dao.getAllForBaby('baby1');
      expect(records, hasLength(1));
      expect(records.first.weightKg, 5.5);
    });

    test('getAllForBaby returns empty for unknown baby', () async {
      final records = await dao.getAllForBaby('unknown');
      expect(records, isEmpty);
    });

    test('getAllForBaby orders by measuredAt descending', () async {
      final earlier = now.subtract(const Duration(hours: 2));
      await dao.insertGrowthRecord(makeRecord(id: 'r1', measuredAt: earlier));
      await dao.insertGrowthRecord(makeRecord(id: 'r2', measuredAt: now));

      final records = await dao.getAllForBaby('baby1');
      expect(records.first.id, 'r2'); // most recent first
      expect(records.last.id, 'r1');
    });

    test('getLatest returns the most recent record', () async {
      final earlier = now.subtract(const Duration(hours: 2));
      await dao.insertGrowthRecord(makeRecord(id: 'r1', measuredAt: earlier));
      await dao.insertGrowthRecord(makeRecord(id: 'r2', measuredAt: now));

      final latest = await dao.getLatest('baby1');
      expect(latest, isNotNull);
      expect(latest!.id, 'r2');
    });

    test('getLatest returns null when no records', () async {
      final latest = await dao.getLatest('baby1');
      expect(latest, isNull);
    });

    test('getInRange returns only records in range', () async {
      final before = now.subtract(const Duration(days: 2));
      await dao.insertGrowthRecord(makeRecord(id: 'r1', measuredAt: before));
      await dao.insertGrowthRecord(makeRecord(id: 'r2', measuredAt: now));

      final start = now.subtract(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 1));
      final records = await dao.getInRange('baby1', start, end);
      expect(records, hasLength(1));
      expect(records.first.id, 'r2');
    });

    test('updateGrowthRecord modifies entry', () async {
      await dao.insertGrowthRecord(makeRecord());
      final updated = GrowthRecordsCompanion(
        id: const Value('r1'),
        babyId: const Value('baby1'),
        measuredAt: Value(now),
        weightKg: const Value(6.5),
        createdAt: Value(now),
        modifiedAt: Value(now),
      );
      await dao.updateGrowthRecord(updated);
      final records = await dao.getAllForBaby('baby1');
      expect(records.first.weightKg, 6.5);
    });

    test('deleteGrowthRecord removes entry', () async {
      await dao.insertGrowthRecord(makeRecord());
      await dao.deleteGrowthRecord('r1');
      final records = await dao.getAllForBaby('baby1');
      expect(records, isEmpty);
    });

    test('watchAllForBaby emits current records', () async {
      await dao.insertGrowthRecord(makeRecord());
      final stream = dao.watchAllForBaby('baby1');
      final records = await stream.first;
      expect(records, hasLength(1));
    });

    test('stores null optional fields', () async {
      await dao.insertGrowthRecord(GrowthRecordsCompanion.insert(
        id: 'r_null',
        babyId: 'baby1',
        measuredAt: now,
        createdAt: now,
        modifiedAt: now,
      ));
      final records = await dao.getAllForBaby('baby1');
      expect(records.first.weightKg, isNull);
      expect(records.first.heightCm, isNull);
      expect(records.first.headCircumferenceCm, isNull);
    });
  });
}
