import '../../../../core/errors/result.dart';
import '../entities/feeding_log.dart';

abstract class FeedingRepository {
  Future<Result<List<FeedingLogEntity>>> getAllForBaby(String babyId);
  Stream<List<FeedingLogEntity>> watchAllForBaby(String babyId);
  Future<Result<FeedingLogEntity?>> getLastFeeding(String babyId);
  Stream<FeedingLogEntity?> watchLastFeeding(String babyId);
  Future<Result<FeedingLogEntity?>> getActiveBreastFeeding(String babyId);
  Future<Result<List<FeedingLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end);
  Future<Result<void>> createFeeding(FeedingLogEntity log);
  Future<Result<void>> updateFeeding(FeedingLogEntity log);
  /// Replaces only a feed's notes; every other column is left as stored.
  Future<Result<void>> updateNotes(String id, String? notes);
  Future<Result<void>> deleteFeeding(String id);
  /// Undo a delete of [log] (the kernel's Restore when sync is on).
  Future<Result<void>> restoreFeeding(FeedingLogEntity log);
}
