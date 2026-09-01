import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'feeding_dao.g.dart';

@DriftAccessor(tables: [FeedingLogs])
class FeedingDao extends DatabaseAccessor<AppDatabase> with _$FeedingDaoMixin {
  FeedingDao(super.db);

  Future<List<FeedingLog>> getAllForBaby(String babyId) =>
      (select(feedingLogs)
            ..where((f) => f.babyId.equals(babyId))
            ..orderBy([(f) => OrderingTerm.desc(f.startTime)]))
          .get();

  Stream<List<FeedingLog>> watchAllForBaby(String babyId) =>
      (select(feedingLogs)
            ..where((f) => f.babyId.equals(babyId))
            ..orderBy([(f) => OrderingTerm.desc(f.startTime)]))
          .watch();

  Future<FeedingLog?> getLastFeeding(String babyId) =>
      (select(feedingLogs)
            ..where((f) => f.babyId.equals(babyId))
            ..orderBy([(f) => OrderingTerm.desc(f.startTime)])
            ..limit(1))
          .getSingleOrNull();

  Future<FeedingLog?> getActiveBreastFeeding(String babyId) =>
      (select(feedingLogs)
            ..where((f) =>
                f.babyId.equals(babyId) &
                f.type.equals('breast') &
                f.endTime.isNull())
            ..limit(1))
          .getSingleOrNull();

  Stream<FeedingLog?> watchLastFeeding(String babyId) =>
      (select(feedingLogs)
            ..where((f) => f.babyId.equals(babyId))
            ..orderBy([(f) => OrderingTerm.desc(f.startTime)])
            ..limit(1))
          .watchSingleOrNull();

  Future<List<FeedingLog>> getInRange(
      String babyId, DateTime start, DateTime end) =>
      (select(feedingLogs)
            ..where((f) =>
                f.babyId.equals(babyId) &
                f.startTime.isBiggerOrEqualValue(start) &
                f.startTime.isSmallerThanValue(end))
            ..orderBy([(f) => OrderingTerm.desc(f.startTime)]))
          .get();

  Future<int> insertFeeding(FeedingLogsCompanion log) =>
      into(feedingLogs).insert(log);

  Future<bool> updateFeeding(FeedingLogsCompanion log) =>
      update(feedingLogs).replace(log);

  /// Writes only the notes column, so a note saved while a feed is open can
  /// never overwrite an endTime written by a Stop that landed first.
  Future<int> updateNotes(String id, String? notes, DateTime modifiedAt) =>
      (update(feedingLogs)..where((f) => f.id.equals(id))).write(
        FeedingLogsCompanion(
          notes: Value(notes),
          modifiedAt: Value(modifiedAt),
        ),
      );

  Future<int> deleteFeeding(String id) =>
      (delete(feedingLogs)..where((f) => f.id.equals(id))).go();
}
