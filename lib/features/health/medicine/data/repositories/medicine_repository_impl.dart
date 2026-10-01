import 'package:drift/drift.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../services/database/database.dart' as db;
import '../../../../../services/database/daos/medicine_dao.dart';
import '../../domain/entities/medicine_log.dart';
import '../../../../sync/data/lullaby_records.dart';
import '../../../../sync/data/record_projection.dart';
import '../../../../sync/data/record_writer.dart';
import '../../domain/repositories/medicine_repository.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  MedicineRepositoryImpl(this._dao, [RecordWriter? writer])
      : _writer = writer ?? DirectRecordWriter(RecordProjection(_dao.attachedDatabase));
  final MedicineDao _dao;

  /// Every change goes through here, so it reaches the household's log when
  /// sync is on (docs/adr/0007-household-sync.md). Reads stay on [_dao].
  final RecordWriter _writer;

  @override
  Future<Result<List<MedicineLogEntity>>> getAllForBaby(String babyId) async {
    try {
      final logs = await _dao.getAllForBaby(babyId);
      return Success(logs.map(_toEntity).toList());
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
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
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> createMedicineLog(MedicineLogEntity log) async {
    try {
      await _writer.put(medicineSpec, log.id, companionFields(medicineSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> updateMedicineLog(MedicineLogEntity log) async {
    try {
      await _writer.update(medicineSpec, log.id, companionFields(medicineSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> deleteMedicineLog(String id) async {
    try {
      await _writer.delete(medicineSpec, id);
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> restoreMedicineLog(MedicineLogEntity log) async {
    try {
      await _writer.restore(medicineSpec, log.id, companionFields(medicineSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
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
