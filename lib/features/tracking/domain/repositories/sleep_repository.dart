import '../../../../core/errors/result.dart';
import '../entities/sleep_log.dart';

abstract class SleepRepository {
  Future<Result<List<SleepLogEntity>>> getAllForBaby(String babyId);
  Stream<List<SleepLogEntity>> watchAllForBaby(String babyId);
  Future<Result<SleepLogEntity?>> getActiveSleep(String babyId);
  Stream<SleepLogEntity?> watchActiveSleep(String babyId);
  Future<Result<SleepLogEntity?>> getLastSleep(String babyId);
  Future<Result<List<SleepLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end);
  Future<Result<void>> createSleep(SleepLogEntity log);
  Future<Result<void>> updateSleep(SleepLogEntity log);
  Future<Result<void>> deleteSleep(String id);
}
