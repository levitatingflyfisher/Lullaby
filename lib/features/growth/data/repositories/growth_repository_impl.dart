import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/database/daos/growth_dao.dart';
import '../../domain/entities/growth_record.dart';
import '../../domain/repositories/growth_repository.dart';

class GrowthRepositoryImpl implements GrowthRepository {
  GrowthRepositoryImpl(this._dao);
  final GrowthDao _dao;

  @override
  Future<Result<List<GrowthRecordEntity>>> getAllForBaby(String babyId) async {
    try {
      final records = await _dao.getAllForBaby(babyId);
      return Success(records.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<List<GrowthRecordEntity>> watchAllForBaby(String babyId) =>
      _dao.watchAllForBaby(babyId).map((l) => l.map(_toEntity).toList());

  @override
  Future<Result<GrowthRecordEntity?>> getLatest(String babyId) async {
    try {
      final record = await _dao.getLatest(babyId);
      return Success(record == null ? null : _toEntity(record));
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<GrowthRecordEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    try {
      final records = await _dao.getInRange(babyId, start, end);
      return Success(records.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> createGrowthRecord(GrowthRecordEntity record) async {
    try {
      await _dao.insertGrowthRecord(_toCompanion(record));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateGrowthRecord(GrowthRecordEntity record) async {
    try {
      await _dao.updateGrowthRecord(_toCompanion(record));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteGrowthRecord(String id) async {
    try {
      await _dao.deleteGrowthRecord(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  static GrowthRecordEntity _toEntity(db.GrowthRecord record) =>
      GrowthRecordEntity(
        id: record.id,
        babyId: record.babyId,
        measuredAt: record.measuredAt,
        weightKg: record.weightKg,
        heightCm: record.heightCm,
        headCircumferenceCm: record.headCircumferenceCm,
        notes: record.notes,
        createdAt: record.createdAt,
        modifiedAt: record.modifiedAt,
      );

  static db.GrowthRecordsCompanion _toCompanion(GrowthRecordEntity record) =>
      db.GrowthRecordsCompanion(
        id: Value(record.id),
        babyId: Value(record.babyId),
        measuredAt: Value(record.measuredAt),
        weightKg: Value(record.weightKg),
        heightCm: Value(record.heightCm),
        headCircumferenceCm: Value(record.headCircumferenceCm),
        notes: Value(record.notes),
        createdAt: Value(record.createdAt),
        modifiedAt: Value(record.modifiedAt),
      );
}
