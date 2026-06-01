import '../../../../core/errors/result.dart';
import '../entities/growth_record.dart';

abstract class GrowthRepository {
  Future<Result<List<GrowthRecordEntity>>> getAllForBaby(String babyId);
  Stream<List<GrowthRecordEntity>> watchAllForBaby(String babyId);
  Future<Result<GrowthRecordEntity?>> getLatest(String babyId);
  Future<Result<List<GrowthRecordEntity>>> getInRange(
      String babyId, DateTime start, DateTime end);
  Future<Result<void>> createGrowthRecord(GrowthRecordEntity record);
  Future<Result<void>> updateGrowthRecord(GrowthRecordEntity record);
  Future<Result<void>> deleteGrowthRecord(String id);
}
