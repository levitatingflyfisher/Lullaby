import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'medicine_dao.g.dart';

@DriftAccessor(tables: [MedicineLogs])
class MedicineDao extends DatabaseAccessor<AppDatabase> with _$MedicineDaoMixin {
  MedicineDao(super.db);

  Future<List<MedicineLog>> getAllForBaby(String babyId) =>
      (select(medicineLogs)
            ..where((m) => m.babyId.equals(babyId))
            ..orderBy([(m) => OrderingTerm.desc(m.administeredAt)]))
          .get();

  Stream<List<MedicineLog>> watchAllForBaby(String babyId) =>
      (select(medicineLogs)
            ..where((m) => m.babyId.equals(babyId))
            ..orderBy([(m) => OrderingTerm.desc(m.administeredAt)]))
          .watch();

  Future<List<MedicineLog>> getInRange(
      String babyId, DateTime start, DateTime end) =>
      (select(medicineLogs)
            ..where((m) =>
                m.babyId.equals(babyId) &
                m.administeredAt.isBiggerOrEqualValue(start) &
                m.administeredAt.isSmallerThanValue(end))
            ..orderBy([(m) => OrderingTerm.desc(m.administeredAt)]))
          .get();

  Future<int> insertMedicineLog(MedicineLogsCompanion log) =>
      into(medicineLogs).insert(log);

  Future<bool> updateMedicineLog(MedicineLogsCompanion log) =>
      update(medicineLogs).replace(log);

  Future<int> deleteMedicineLog(String id) =>
      (delete(medicineLogs)..where((m) => m.id.equals(id))).go();
}
