import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'growth_dao.g.dart';

@DriftAccessor(tables: [GrowthRecords])
class GrowthDao extends DatabaseAccessor<AppDatabase> with _$GrowthDaoMixin {
  GrowthDao(super.db);

  Future<List<GrowthRecord>> getAllForBaby(String babyId) =>
      (select(growthRecords)
            ..where((g) => g.babyId.equals(babyId))
            ..orderBy([(g) => OrderingTerm.desc(g.measuredAt)]))
          .get();

  Stream<List<GrowthRecord>> watchAllForBaby(String babyId) =>
      (select(growthRecords)
            ..where((g) => g.babyId.equals(babyId))
            ..orderBy([(g) => OrderingTerm.desc(g.measuredAt)]))
          .watch();

  Future<GrowthRecord?> getLatest(String babyId) =>
      (select(growthRecords)
            ..where((g) => g.babyId.equals(babyId))
            ..orderBy([(g) => OrderingTerm.desc(g.measuredAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<GrowthRecord>> getInRange(
      String babyId, DateTime start, DateTime end) =>
      (select(growthRecords)
            ..where((g) =>
                g.babyId.equals(babyId) &
                g.measuredAt.isBiggerOrEqualValue(start) &
                g.measuredAt.isSmallerThanValue(end))
            ..orderBy([(g) => OrderingTerm.desc(g.measuredAt)]))
          .get();

  Future<int> insertGrowthRecord(GrowthRecordsCompanion record) =>
      into(growthRecords).insert(record);

  Future<bool> updateGrowthRecord(GrowthRecordsCompanion record) =>
      update(growthRecords).replace(record);

  Future<int> deleteGrowthRecord(String id) =>
      (delete(growthRecords)..where((g) => g.id.equals(id))).go();
}
