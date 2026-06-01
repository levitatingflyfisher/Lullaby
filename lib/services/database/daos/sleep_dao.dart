import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'sleep_dao.g.dart';

@DriftAccessor(tables: [SleepLogs])
class SleepDao extends DatabaseAccessor<AppDatabase> with _$SleepDaoMixin {
  SleepDao(super.db);

  Future<List<SleepLog>> getAllForBaby(String babyId) =>
      (select(sleepLogs)
            ..where((s) => s.babyId.equals(babyId))
            ..orderBy([(s) => OrderingTerm.desc(s.startTime)]))
          .get();

  Stream<List<SleepLog>> watchAllForBaby(String babyId) =>
      (select(sleepLogs)
            ..where((s) => s.babyId.equals(babyId))
            ..orderBy([(s) => OrderingTerm.desc(s.startTime)]))
          .watch();

  Future<SleepLog?> getActiveSleep(String babyId) =>
      (select(sleepLogs)
            ..where(
                (s) => s.babyId.equals(babyId) & s.endTime.isNull())
            ..limit(1))
          .getSingleOrNull();

  Future<SleepLog?> getLastSleep(String babyId) =>
      (select(sleepLogs)
            ..where((s) => s.babyId.equals(babyId))
            ..orderBy([(s) => OrderingTerm.desc(s.startTime)])
            ..limit(1))
          .getSingleOrNull();

  Stream<SleepLog?> watchActiveSleep(String babyId) =>
      (select(sleepLogs)
            ..where(
                (s) => s.babyId.equals(babyId) & s.endTime.isNull())
            ..limit(1))
          .watchSingleOrNull();

  Future<List<SleepLog>> getInRange(
      String babyId, DateTime start, DateTime end) =>
      (select(sleepLogs)
            ..where((s) =>
                s.babyId.equals(babyId) &
                s.startTime.isBiggerOrEqualValue(start) &
                s.startTime.isSmallerThanValue(end))
            ..orderBy([(s) => OrderingTerm.desc(s.startTime)]))
          .get();

  Future<int> insertSleep(SleepLogsCompanion log) =>
      into(sleepLogs).insert(log);

  Future<bool> updateSleep(SleepLogsCompanion log) =>
      update(sleepLogs).replace(log);

  Future<int> deleteSleep(String id) =>
      (delete(sleepLogs)..where((s) => s.id.equals(id))).go();
}
