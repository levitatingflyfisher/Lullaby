import 'package:drift/drift.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../services/database/database.dart' as db;
import '../../../../../services/database/daos/medicine_dao.dart';
import '../../domain/entities/medicine_log.dart';
import '../../domain/repositories/medicine_repository.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  MedicineRepositoryImpl(this._dao);
  final MedicineDao _dao;

  @override
  Future<Result<List<MedicineLogEntity>>> getAllForBaby(String babyId) async {
    try {
      final logs = await _dao.getAllForBaby(babyId);
      return Success(logs.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<List<MedicineLogEntity>> watchAllForBaby(String babyId) =>
      _dao.watchAllForBaby(babyId).map((l) => l.map(_toEntity).toList());

  @override
  Future<Result<List<MedicineLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    try {
      final logs = await _dao.getInRange(babyId, start, end);
      return Success(logs.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> createMedicineLog(MedicineLogEntity log) async {
    try {
      await _dao.insertMedicineLog(_toCompanion(log));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateMedicineLog(MedicineLogEntity log) async {
    try {
      await _dao.updateMedicineLog(_toCompanion(log));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteMedicineLog(String id) async {
    try {
      await _dao.deleteMedicineLog(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  static MedicineLogEntity _toEntity(db.MedicineLog log) => MedicineLogEntity(
        id: log.id,
        babyId: log.babyId,
        medicineName: log.medicineName,
        dosage: log.dosage,
        dosageUnit: log.dosageUnit,
        administeredAt: log.administeredAt,
        notes: log.notes,
        createdAt: log.createdAt,
        modifiedAt: log.modifiedAt,
      );

  static db.MedicineLogsCompanion _toCompanion(MedicineLogEntity log) =>
      db.MedicineLogsCompanion(
        id: Value(log.id),
        babyId: Value(log.babyId),
        medicineName: Value(log.medicineName),
        dosage: Value(log.dosage),
        dosageUnit: Value(log.dosageUnit),
        administeredAt: Value(log.administeredAt),
        notes: Value(log.notes),
        createdAt: Value(log.createdAt),
        modifiedAt: Value(log.modifiedAt),
      );
}
