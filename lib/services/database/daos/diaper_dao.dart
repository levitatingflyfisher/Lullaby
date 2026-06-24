import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'diaper_dao.g.dart';

@DriftAccessor(tables: [DiaperLogs])
class DiaperDao extends DatabaseAccessor<AppDatabase> with _$DiaperDaoMixin {
  DiaperDao(super.db);

  Future<List<DiaperLog>> getAllForBaby(String babyId) =>
      (select(diaperLogs)
            ..where((d) => d.babyId.equals(babyId))
            ..orderBy([(d) => OrderingTerm.desc(d.time)]))
          .get();

  Future<DiaperLog?> getLastDiaper(String babyId) =>
      (select(diaperLogs)
            ..where((d) => d.babyId.equals(babyId))
            ..orderBy([(d) => OrderingTerm.desc(d.time)])
            ..limit(1))
          .getSingleOrNull();

  Stream<List<DiaperLog>> watchAllForBaby(String babyId) =>
      (select(diaperLogs)
            ..where((d) => d.babyId.equals(babyId))
            ..orderBy([(d) => OrderingTerm.desc(d.time)]))
          .watch();

  Future<List<DiaperLog>> getInRange(
      String babyId, DateTime start, DateTime end) =>
      (select(diaperLogs)
            ..where((d) =>
                d.babyId.equals(babyId) &
                d.time.isBiggerOrEqualValue(start) &
                d.time.isSmallerThanValue(end))
            ..orderBy([(d) => OrderingTerm.desc(d.time)]))
          .get();

  Future<int> countByTypeInRange(
      String babyId, String type, DateTime start, DateTime end) async {
    final query = select(diaperLogs)
      ..where((d) =>
          d.babyId.equals(babyId) &
          d.type.equals(type) &
          d.time.isBiggerOrEqualValue(start) &
          d.time.isSmallerThanValue(end));
    final results = await query.get();
    return results.length;
  }

  Future<int> countInRange(String babyId, DateTime start, DateTime end) async {
    final query = select(diaperLogs)
      ..where((d) =>
          d.babyId.equals(babyId) &
          d.time.isBiggerOrEqualValue(start) &
          d.time.isSmallerThanValue(end));
    final results = await query.get();
    return results.length;
  }

  Future<int> insertDiaper(DiaperLogsCompanion log) =>
      into(diaperLogs).insert(log);

  Future<bool> updateDiaper(DiaperLogsCompanion log) =>
      update(diaperLogs).replace(log);

  Future<int> deleteDiaper(String id) =>
      (delete(diaperLogs)..where((d) => d.id.equals(id))).go();
}
