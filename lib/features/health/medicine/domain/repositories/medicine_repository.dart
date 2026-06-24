import '../../../../../core/errors/result.dart';
import '../entities/medicine_log.dart';

abstract class MedicineRepository {
  Future<Result<List<MedicineLogEntity>>> getAllForBaby(String babyId);
  Stream<List<MedicineLogEntity>> watchAllForBaby(String babyId);
  Future<Result<List<MedicineLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end);
  Future<Result<void>> createMedicineLog(MedicineLogEntity log);
  Future<Result<void>> updateMedicineLog(MedicineLogEntity log);
  Future<Result<void>> deleteMedicineLog(String id);
}
