import 'package:drift/drift.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../services/database/database.dart' as db;
import '../../../../../services/database/daos/vaccine_dao.dart';
import '../../domain/entities/vaccine_record.dart';
import '../../domain/repositories/vaccine_repository.dart';

class VaccineRepositoryImpl implements VaccineRepository {
  VaccineRepositoryImpl(this._dao);
  final VaccineDao _dao;

  @override
  Future<Result<List<VaccineRecordEntity>>> getAllForBaby(String babyId) async {
    try {
      final records = await _dao.getAllForBaby(babyId);
      return Success(records.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
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
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<VaccineRecordEntity>>> getAdministered(
      String babyId) async {
    try {
      final records = await _dao.getAdministered(babyId);
      return Success(records.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> createVaccineRecord(VaccineRecordEntity record) async {
    try {
      await _dao.insertVaccineRecord(_toCompanion(record));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateVaccineRecord(VaccineRecordEntity record) async {
    try {
      await _dao.updateVaccineRecord(_toCompanion(record));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteVaccineRecord(String id) async {
    try {
      await _dao.deleteVaccineRecord(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
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
