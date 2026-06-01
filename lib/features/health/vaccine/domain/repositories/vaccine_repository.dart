import '../../../../../core/errors/result.dart';
import '../entities/vaccine_record.dart';

abstract class VaccineRepository {
  Future<Result<List<VaccineRecordEntity>>> getAllForBaby(String babyId);
  Stream<List<VaccineRecordEntity>> watchAllForBaby(String babyId);
  Future<Result<List<VaccineRecordEntity>>> getUpcoming(String babyId);
  Future<Result<List<VaccineRecordEntity>>> getAdministered(String babyId);
  Future<Result<void>> createVaccineRecord(VaccineRecordEntity record);
  Future<Result<void>> updateVaccineRecord(VaccineRecordEntity record);
  Future<Result<void>> deleteVaccineRecord(String id);
}
