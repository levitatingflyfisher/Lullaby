import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'vaccine_dao.g.dart';

@DriftAccessor(tables: [VaccineRecords])
class VaccineDao extends DatabaseAccessor<AppDatabase> with _$VaccineDaoMixin {
  VaccineDao(super.db);

  Future<List<VaccineRecord>> getAllForBaby(String babyId) =>
      (select(vaccineRecords)
            ..where((v) => v.babyId.equals(babyId))
            ..orderBy([
              (v) => OrderingTerm(
                    expression: v.administeredDate,
                    mode: OrderingMode.desc,
                    nulls: NullsOrder.last,
                  ),
            ]))
          .get();

  Stream<List<VaccineRecord>> watchAllForBaby(String babyId) =>
      (select(vaccineRecords)
            ..where((v) => v.babyId.equals(babyId))
            ..orderBy([
              (v) => OrderingTerm(
                    expression: v.administeredDate,
                    mode: OrderingMode.desc,
                    nulls: NullsOrder.last,
                  ),
            ]))
          .watch();

  Future<List<VaccineRecord>> getUpcoming(String babyId) =>
      (select(vaccineRecords)
            ..where((v) =>
                v.babyId.equals(babyId) &
                v.scheduledDate.isNotNull() &
                v.administeredDate.isNull()))
          .get();

  Future<List<VaccineRecord>> getAdministered(String babyId) =>
      (select(vaccineRecords)
            ..where((v) =>
                v.babyId.equals(babyId) & v.administeredDate.isNotNull())
            ..orderBy([(v) => OrderingTerm.desc(v.administeredDate)]))
          .get();

  Future<int> insertVaccineRecord(VaccineRecordsCompanion record) =>
      into(vaccineRecords).insert(record);

  Future<bool> updateVaccineRecord(VaccineRecordsCompanion record) =>
      update(vaccineRecords).replace(record);

  Future<int> deleteVaccineRecord(String id) =>
      (delete(vaccineRecords)..where((v) => v.id.equals(id))).go();
}
