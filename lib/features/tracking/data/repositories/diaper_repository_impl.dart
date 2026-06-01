import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/database/daos/diaper_dao.dart';
import '../../domain/entities/diaper_log.dart';
import '../../domain/repositories/diaper_repository.dart';

class DiaperRepositoryImpl implements DiaperRepository {
  DiaperRepositoryImpl(this._dao);
  final DiaperDao _dao;

  @override
  Future<Result<List<DiaperLogEntity>>> getAllForBaby(String babyId) async {
    try {
      final logs = await _dao.getAllForBaby(babyId);
      return Success(logs.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<List<DiaperLogEntity>> watchAllForBaby(String babyId) =>
      _dao.watchAllForBaby(babyId).map((l) => l.map(_toEntity).toList());

  @override
  Future<Result<List<DiaperLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    try {
      final logs = await _dao.getInRange(babyId, start, end);
      return Success(logs.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> countInRange(
      String babyId, DateTime start, DateTime end) async {
    try {
      final count = await _dao.countInRange(babyId, start, end);
      return Success(count);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> countByTypeInRange(
      String babyId, DiaperType type, DateTime start, DateTime end) async {
    try {
      final count =
          await _dao.countByTypeInRange(babyId, type.name, start, end);
      return Success(count);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<DiaperLogEntity?>> getLastDiaper(String babyId) async {
    try {
      final log = await _dao.getLastDiaper(babyId);
      return Success(log == null ? null : _toEntity(log));
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> createDiaper(DiaperLogEntity log) async {
    try {
      await _dao.insertDiaper(_toCompanion(log));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateDiaper(DiaperLogEntity log) async {
    try {
      await _dao.updateDiaper(_toCompanion(log));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteDiaper(String id) async {
    try {
      await _dao.deleteDiaper(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  static DiaperLogEntity _toEntity(db.DiaperLog log) => DiaperLogEntity(
        id: log.id,
        babyId: log.babyId,
        time: log.time,
        type: DiaperType.fromString(log.type),
        color: StoolColor.fromString(log.color),
        notes: log.notes,
        createdAt: log.createdAt,
        modifiedAt: log.modifiedAt,
      );

  static db.DiaperLogsCompanion _toCompanion(DiaperLogEntity log) =>
      db.DiaperLogsCompanion(
        id: Value(log.id),
        babyId: Value(log.babyId),
        time: Value(log.time),
        type: Value(log.type.name),
        color: Value(log.color?.name),
        notes: Value(log.notes),
        createdAt: Value(log.createdAt),
        modifiedAt: Value(log.modifiedAt),
      );
}
