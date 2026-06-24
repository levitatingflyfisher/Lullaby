import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/health/medicine/data/repositories/medicine_repository_impl.dart';
import 'package:lullaby/features/health/medicine/domain/entities/medicine_log.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late MedicineRepositoryImpl repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MedicineRepositoryImpl(db.medicineDao);
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  MedicineLogEntity makeEntity({
    String id = 'log1',
    String medicineName = 'Tylenol',
    double? dosage = 2.5,
    String? dosageUnit = 'ml',
    DateTime? administeredAt,
  }) =>
      MedicineLogEntity(
        id: id,
        babyId: 'baby1',
        medicineName: medicineName,
        dosage: dosage,
        dosageUnit: dosageUnit,
        administeredAt: administeredAt ?? now,
        createdAt: now,
        modifiedAt: now,
      );

  group('MedicineRepositoryImpl', () {
    test('createMedicineLog and getAllForBaby mapping', () async {
      final entity = makeEntity();
      final result = await repo.createMedicineLog(entity);
      expect(result, isA<Success>());

      final getResult = await repo.getAllForBaby('baby1');
      expect(getResult, isA<Success<List<MedicineLogEntity>>>());
      final logs = (getResult as Success<List<MedicineLogEntity>>).value;
      expect(logs, hasLength(1));
      expect(logs.first.medicineName, 'Tylenol');
      expect(logs.first.dosage, 2.5);
      expect(logs.first.dosageUnit, 'ml');
    });

    test('getAllForBaby returns empty list', () async {
      final result = await repo.getAllForBaby('baby1');
      expect(result, isA<Success<List<MedicineLogEntity>>>());
      expect((result as Success<List<MedicineLogEntity>>).value, isEmpty);
    });

    test('updateMedicineLog updates entry', () async {
      await repo.createMedicineLog(makeEntity());
      final updated = makeEntity(medicineName: 'Ibuprofen', dosage: 5.0);
      final updateResult = await repo.updateMedicineLog(updated);
      expect(updateResult, isA<Success>());

      final logs =
          (await repo.getAllForBaby('baby1') as Success<List<MedicineLogEntity>>)
              .value;
      expect(logs.first.medicineName, 'Ibuprofen');
      expect(logs.first.dosage, 5.0);
    });

    test('deleteMedicineLog removes entry', () async {
      await repo.createMedicineLog(makeEntity());
      final deleteResult = await repo.deleteMedicineLog('log1');
      expect(deleteResult, isA<Success>());

      final logs =
          (await repo.getAllForBaby('baby1') as Success<List<MedicineLogEntity>>)
              .value;
      expect(logs, isEmpty);
    });

    test('getInRange returns logs in date range', () async {
      final before = now.subtract(const Duration(days: 2));
      await repo.createMedicineLog(
          makeEntity(id: 'log1', administeredAt: before));
      await repo.createMedicineLog(makeEntity(id: 'log2'));

      final start = now.subtract(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 1));
      final result = await repo.getInRange('baby1', start, end);
      expect(result, isA<Success<List<MedicineLogEntity>>>());
      final logs = (result as Success<List<MedicineLogEntity>>).value;
      expect(logs, hasLength(1));
      expect(logs.first.id, 'log2');
    });

    test('watchAllForBaby emits mapped entities', () async {
      await repo.createMedicineLog(makeEntity());
      final stream = repo.watchAllForBaby('baby1');
      final logs = await stream.first;
      expect(logs, hasLength(1));
      expect(logs.first, isA<MedicineLogEntity>());
      expect(logs.first.babyId, 'baby1');
    });
  });
}
