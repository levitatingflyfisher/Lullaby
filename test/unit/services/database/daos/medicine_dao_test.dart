import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:lullaby/services/database/daos/medicine_dao.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late MedicineDao dao;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.medicineDao;
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  MedicineLogsCompanion makeLog({
    String id = 'log1',
    DateTime? administeredAt,
    String medicineName = 'Tylenol',
    double? dosage = 2.5,
  }) =>
      MedicineLogsCompanion.insert(
        id: id,
        babyId: 'baby1',
        medicineName: medicineName,
        administeredAt: administeredAt ?? now,
        dosage: dosage != null ? Value(dosage) : const Value.absent(),
        createdAt: now,
        modifiedAt: now,
      );

  group('MedicineDao', () {
    test('insertMedicineLog and getAllForBaby', () async {
      await dao.insertMedicineLog(makeLog());
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, hasLength(1));
      expect(logs.first.medicineName, 'Tylenol');
      expect(logs.first.dosage, 2.5);
    });

    test('getAllForBaby returns empty for unknown baby', () async {
      final logs = await dao.getAllForBaby('unknown');
      expect(logs, isEmpty);
    });

    test('getAllForBaby orders by administeredAt descending', () async {
      final earlier = now.subtract(const Duration(hours: 2));
      await dao.insertMedicineLog(makeLog(id: 'log1', administeredAt: earlier));
      await dao.insertMedicineLog(makeLog(id: 'log2', administeredAt: now));

      final logs = await dao.getAllForBaby('baby1');
      expect(logs.first.id, 'log2');
      expect(logs.last.id, 'log1');
    });

    test('getInRange returns only logs in range', () async {
      final before = now.subtract(const Duration(days: 2));
      await dao.insertMedicineLog(
          makeLog(id: 'log1', administeredAt: before));
      await dao.insertMedicineLog(makeLog(id: 'log2', administeredAt: now));

      final start = now.subtract(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 1));
      final logs = await dao.getInRange('baby1', start, end);
      expect(logs, hasLength(1));
      expect(logs.first.id, 'log2');
    });

    test('updateMedicineLog modifies entry', () async {
      await dao.insertMedicineLog(makeLog());
      final updated = MedicineLogsCompanion(
        id: const Value('log1'),
        babyId: const Value('baby1'),
        medicineName: const Value('Ibuprofen'),
        administeredAt: Value(now),
        dosage: const Value(5.0),
        createdAt: Value(now),
        modifiedAt: Value(now),
      );
      await dao.updateMedicineLog(updated);
      final logs = await dao.getAllForBaby('baby1');
      expect(logs.first.medicineName, 'Ibuprofen');
      expect(logs.first.dosage, 5.0);
    });

    test('deleteMedicineLog removes entry', () async {
      await dao.insertMedicineLog(makeLog());
      await dao.deleteMedicineLog('log1');
      final logs = await dao.getAllForBaby('baby1');
      expect(logs, isEmpty);
    });

    test('watchAllForBaby emits current logs', () async {
      await dao.insertMedicineLog(makeLog());
      final stream = dao.watchAllForBaby('baby1');
      final logs = await stream.first;
      expect(logs, hasLength(1));
    });

    test('stores null optional fields', () async {
      await dao.insertMedicineLog(MedicineLogsCompanion.insert(
        id: 'log_null',
        babyId: 'baby1',
        medicineName: 'Vitamin D',
        administeredAt: now,
        createdAt: now,
        modifiedAt: now,
      ));
      final logs = await dao.getAllForBaby('baby1');
      expect(logs.first.dosage, isNull);
      expect(logs.first.dosageUnit, isNull);
      expect(logs.first.notes, isNull);
    });
  });
}
