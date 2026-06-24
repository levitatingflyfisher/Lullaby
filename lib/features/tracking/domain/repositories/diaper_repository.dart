import '../../../../core/errors/result.dart';
import '../entities/diaper_log.dart';

abstract class DiaperRepository {
  Future<Result<List<DiaperLogEntity>>> getAllForBaby(String babyId);
  Stream<List<DiaperLogEntity>> watchAllForBaby(String babyId);
  Future<Result<List<DiaperLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end);
  Future<Result<int>> countInRange(
      String babyId, DateTime start, DateTime end);
  Future<Result<int>> countByTypeInRange(
      String babyId, DiaperType type, DateTime start, DateTime end);
  Future<Result<DiaperLogEntity?>> getLastDiaper(String babyId);
  Future<Result<void>> createDiaper(DiaperLogEntity log);
  Future<Result<void>> updateDiaper(DiaperLogEntity log);
  Future<Result<void>> deleteDiaper(String id);
}
