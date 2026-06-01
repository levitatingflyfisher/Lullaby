import '../../../../core/errors/result.dart';
import '../entities/baby.dart';

abstract class BabyRepository {
  Future<Result<List<BabyEntity>>> getAllBabies();
  Stream<List<BabyEntity>> watchAllBabies();
  Future<Result<BabyEntity>> getBabyById(String id);
  Stream<BabyEntity?> watchActiveBaby();
  Future<Result<void>> createBaby(BabyEntity baby);
  Future<Result<void>> updateBaby(BabyEntity baby);
  Future<Result<void>> deleteBaby(String id);
  Future<Result<void>> setActiveBaby(String id);
}
