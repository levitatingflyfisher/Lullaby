import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:lullaby/services/database/daos/vaccine_dao.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late VaccineDao dao;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.vaccineDao;
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  VaccineRecordsCompanion makeRecord({
    String id = 'v1',
    String vaccineName = 'DTaP',
    DateTime? scheduledDate,
    DateTime? administeredDate,
  }) =>
      VaccineRecordsCompanion.insert(
        id: id,
        babyId: 'baby1',
        vaccineName: vaccineName,
        scheduledDate: scheduledDate != null
            ? Value(scheduledDate)
            : const Value.absent(),
        administeredDate: administeredDate != null
            ? Value(administeredDate)
            : const Value.absent(),
        createdAt: now,
        modifiedAt: now,
      );

  group('VaccineDao', () {
    test('insertVaccineRecord and getAllForBaby', () async {
      await dao.insertVaccineRecord(makeRecord());
      final records = await dao.getAllForBaby('baby1');
      expect(records, hasLength(1));
      expect(records.first.vaccineName, 'DTaP');
    });

    test('getAllForBaby returns empty for unknown baby', () async {
      final records = await dao.getAllForBaby('unknown');
      expect(records, isEmpty);
    });

    test('getUpcoming returns scheduled but not administered', () async {
      final future = now.add(const Duration(days: 30));
      await dao.insertVaccineRecord(
          makeRecord(id: 'v1', scheduledDate: future));
      await dao.insertVaccineRecord(makeRecord(
          id: 'v2',
          scheduledDate: now.subtract(const Duration(days: 7)),
          administeredDate: now));

      final upcoming = await dao.getUpcoming('baby1');
      expect(upcoming, hasLength(1));
      expect(upcoming.first.id, 'v1');
    });

    test('getAdministered returns only administered records', () async {
      await dao.insertVaccineRecord(
          makeRecord(id: 'v1', scheduledDate: now, administeredDate: now));
      await dao
          .insertVaccineRecord(makeRecord(id: 'v2', scheduledDate: now));

      final administered = await dao.getAdministered('baby1');
      expect(administered, hasLength(1));
      expect(administered.first.id, 'v1');
    });

    test('getUpcoming returns empty when no upcoming records', () async {
      await dao.insertVaccineRecord(
          makeRecord(id: 'v1', administeredDate: now));
      final upcoming = await dao.getUpcoming('baby1');
      expect(upcoming, isEmpty);
    });

    test('updateVaccineRecord modifies entry', () async {
      await dao.insertVaccineRecord(makeRecord());
      final updated = VaccineRecordsCompanion(
        id: const Value('v1'),
        babyId: const Value('baby1'),
        vaccineName: const Value('MMR'),
        administeredDate: Value(now),
        createdAt: Value(now),
        modifiedAt: Value(now),
      );
      await dao.updateVaccineRecord(updated);
      final records = await dao.getAllForBaby('baby1');
      expect(records.first.vaccineName, 'MMR');
      expect(records.first.administeredDate, now);
    });

    test('deleteVaccineRecord removes entry', () async {
      await dao.insertVaccineRecord(makeRecord());
      await dao.deleteVaccineRecord('v1');
      final records = await dao.getAllForBaby('baby1');
      expect(records, isEmpty);
    });

    test('watchAllForBaby emits current records', () async {
      await dao.insertVaccineRecord(makeRecord());
      final stream = dao.watchAllForBaby('baby1');
      final records = await stream.first;
      expect(records, hasLength(1));
    });

    test('stores null optional fields', () async {
      await dao.insertVaccineRecord(VaccineRecordsCompanion.insert(
        id: 'v_null',
        babyId: 'baby1',
        vaccineName: 'Flu',
        createdAt: now,
        modifiedAt: now,
      ));
      final records = await dao.getAllForBaby('baby1');
      expect(records.first.doseNumber, isNull);
      expect(records.first.scheduledDate, isNull);
      expect(records.first.administeredDate, isNull);
      expect(records.first.provider, isNull);
    });
  });
}
