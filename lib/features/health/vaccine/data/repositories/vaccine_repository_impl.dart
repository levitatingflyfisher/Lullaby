import 'package:drift/drift.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../services/database/database.dart' as db;
import '../../../../../services/database/daos/vaccine_dao.dart';
import '../../domain/entities/vaccine_record.dart';
import '../../../../sync/data/lullaby_records.dart';
import '../../../../sync/data/record_projection.dart';
import '../../../../sync/data/record_writer.dart';
import '../../domain/repositories/vaccine_repository.dart';

class VaccineRepositoryImpl implements VaccineRepository {
  VaccineRepositoryImpl(this._dao, [RecordWriter? writer])
      : _writer = writer ?? DirectRecordWriter(RecordProjection(_dao.attachedDatabase));
  final VaccineDao _dao;

  /// Every change goes through here, so it reaches the household's log when
  /// sync is on (docs/adr/0007-household-sync.md). Reads stay on [_dao].
  final RecordWriter _writer;

  @override
  Future<Result<List<VaccineRecordEntity>>> getAllForBaby(String babyId) async {
    try {
      final records = await _dao.getAllForBaby(babyId);
      return Success(records.map(_toEntity).toList());
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Stream<List<VaccineRecordEntity>> watchAllForBaby(String babyId) =>
      _dao.watchAllForBaby(babyId).map((l) => l.map(_toEntity).toList());

  @override
  Future<Result<List<VaccineRecordEntity>>> getUpcoming(String babyId) async {
    try {
      final records = await _dao.getUpcoming(babyId);
      return Success(records.map(_toEntity).toList());
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<List<VaccineRecordEntity>>> getAdministered(
      String babyId) async {
    try {
      final records = await _dao.getAdministered(babyId);
      return Success(records.map(_toEntity).toList());
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> createVaccineRecord(VaccineRecordEntity record) async {
    try {
      await _writer.put(vaccineSpec, record.id, companionFields(vaccineSpec, _toCompanion(record)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> updateVaccineRecord(VaccineRecordEntity record) async {
    try {
      await _writer.update(vaccineSpec, record.id, companionFields(vaccineSpec, _toCompanion(record)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> deleteVaccineRecord(String id) async {
    try {
      await _writer.delete(vaccineSpec, id);
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> restoreVaccineRecord(VaccineRecordEntity record) async {
    try {
      await _writer.restore(vaccineSpec, record.id, companionFields(vaccineSpec, _toCompanion(record)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  static VaccineRecordEntity _toEntity(db.VaccineRecord record) =>
      VaccineRecordEntity(
        id: record.id,
        babyId: record.babyId,
        vaccineName: record.vaccineName,
        doseNumber: record.doseNumber,
        scheduledDate: record.scheduledDate,
        administeredDate: record.administeredDate,
        provider: record.provider,
        notes: record.notes,
        createdAt: record.createdAt,
        modifiedAt: record.modifiedAt,
      );

  static db.VaccineRecordsCompanion _toCompanion(VaccineRecordEntity record) =>
      db.VaccineRecordsCompanion(
        id: Value(record.id),
        babyId: Value(record.babyId),
        vaccineName: Value(record.vaccineName),
        doseNumber: Value(record.doseNumber),
        scheduledDate: Value(record.scheduledDate),
        administeredDate: Value(record.administeredDate),
        provider: Value(record.provider),
        notes: Value(record.notes),
        createdAt: Value(record.createdAt),
        modifiedAt: Value(record.modifiedAt),
      );
}
