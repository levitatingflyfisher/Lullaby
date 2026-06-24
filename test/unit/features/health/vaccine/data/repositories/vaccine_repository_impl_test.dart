import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/health/vaccine/data/repositories/vaccine_repository_impl.dart';
import 'package:lullaby/features/health/vaccine/domain/entities/vaccine_record.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late VaccineRepositoryImpl repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VaccineRepositoryImpl(db.vaccineDao);
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  VaccineRecordEntity makeEntity({
    String id = 'v1',
    String vaccineName = 'DTaP',
    int? doseNumber = 1,
    DateTime? scheduledDate,
    DateTime? administeredDate,
    String? provider,
  }) =>
      VaccineRecordEntity(
        id: id,
        babyId: 'baby1',
        vaccineName: vaccineName,
        doseNumber: doseNumber,
        scheduledDate: scheduledDate,
        administeredDate: administeredDate,
        provider: provider,
        createdAt: now,
        modifiedAt: now,
      );

  group('VaccineRepositoryImpl', () {
    test('createVaccineRecord and getAllForBaby mapping', () async {
      final entity = makeEntity();
      final result = await repo.createVaccineRecord(entity);
      expect(result, isA<Success>());

      final getResult = await repo.getAllForBaby('baby1');
      expect(getResult, isA<Success<List<VaccineRecordEntity>>>());
      final records = (getResult as Success<List<VaccineRecordEntity>>).value;
      expect(records, hasLength(1));
      expect(records.first.vaccineName, 'DTaP');
      expect(records.first.doseNumber, 1);
    });

    test('getAllForBaby returns empty list', () async {
      final result = await repo.getAllForBaby('baby1');
      expect(result, isA<Success<List<VaccineRecordEntity>>>());
      expect((result as Success<List<VaccineRecordEntity>>).value, isEmpty);
    });

    test('getUpcoming returns scheduled but not administered', () async {
      final future = now.add(const Duration(days: 30));
      await repo.createVaccineRecord(
          makeEntity(id: 'v1', scheduledDate: future));
      await repo.createVaccineRecord(makeEntity(
          id: 'v2',
          scheduledDate: now.subtract(const Duration(days: 7)),
          administeredDate: now));

      final result = await repo.getUpcoming('baby1');
      expect(result, isA<Success<List<VaccineRecordEntity>>>());
      final records = (result as Success<List<VaccineRecordEntity>>).value;
      expect(records, hasLength(1));
      expect(records.first.id, 'v1');
    });

    test('getAdministered returns only administered records', () async {
      await repo.createVaccineRecord(
          makeEntity(id: 'v1', administeredDate: now));
      await repo.createVaccineRecord(makeEntity(id: 'v2'));

      final result = await repo.getAdministered('baby1');
      expect(result, isA<Success<List<VaccineRecordEntity>>>());
      final records = (result as Success<List<VaccineRecordEntity>>).value;
      expect(records, hasLength(1));
      expect(records.first.id, 'v1');
    });

    test('updateVaccineRecord modifies entry', () async {
      await repo.createVaccineRecord(makeEntity());
      final updated =
          makeEntity(vaccineName: 'MMR', administeredDate: now);
      final updateResult = await repo.updateVaccineRecord(updated);
      expect(updateResult, isA<Success>());

      final records =
          (await repo.getAllForBaby('baby1') as Success<List<VaccineRecordEntity>>)
              .value;
      expect(records.first.vaccineName, 'MMR');
      expect(records.first.administeredDate, now);
    });

    test('deleteVaccineRecord removes entry', () async {
      await repo.createVaccineRecord(makeEntity());
      final deleteResult = await repo.deleteVaccineRecord('v1');
      expect(deleteResult, isA<Success>());

      final records =
          (await repo.getAllForBaby('baby1') as Success<List<VaccineRecordEntity>>)
              .value;
      expect(records, isEmpty);
    });

    test('watchAllForBaby emits mapped entities', () async {
      await repo.createVaccineRecord(makeEntity());
      final stream = repo.watchAllForBaby('baby1');
      final records = await stream.first;
      expect(records, hasLength(1));
      expect(records.first, isA<VaccineRecordEntity>());
      expect(records.first.babyId, 'baby1');
    });
  });
}
