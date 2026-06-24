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
  Future<Result<void>> deleteFeeding(String id);
}
