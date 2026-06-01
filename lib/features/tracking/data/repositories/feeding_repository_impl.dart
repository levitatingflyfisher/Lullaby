import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/database/daos/feeding_dao.dart';
import '../../domain/entities/feeding_log.dart';
import '../../domain/repositories/feeding_repository.dart';

class FeedingRepositoryImpl implements FeedingRepository {
  FeedingRepositoryImpl(this._dao);
  final FeedingDao _dao;

  @override
  Future<Result<List<FeedingLogEntity>>> getAllForBaby(String babyId) async {
    try {
      final logs = await _dao.getAllForBaby(babyId);
      return Success(logs.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<List<FeedingLogEntity>> watchAllForBaby(String babyId) =>
      _dao.watchAllForBaby(babyId).map((l) => l.map(_toEntity).toList());

  @override
  Future<Result<FeedingLogEntity?>> getLastFeeding(String babyId) async {
    try {
      final log = await _dao.getLastFeeding(babyId);
      return Success(log == null ? null : _toEntity(log));
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<FeedingLogEntity?> watchLastFeeding(String babyId) =>
      _dao.watchLastFeeding(babyId).map((l) => l == null ? null : _toEntity(l));

  @override
  Future<Result<FeedingLogEntity?>> getActiveBreastFeeding(String babyId) async {
    try {
      final log = await _dao.getActiveBreastFeeding(babyId);
      return Success(log == null ? null : _toEntity(log));
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<FeedingLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    try {
      final logs = await _dao.getInRange(babyId, start, end);
      return Success(logs.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> createFeeding(FeedingLogEntity log) async {
    try {
      await _dao.insertFeeding(_toCompanion(log));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateFeeding(FeedingLogEntity log) async {
    try {
      await _dao.updateFeeding(_toCompanion(log));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFeeding(String id) async {
    try {
      await _dao.deleteFeeding(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  static FeedingLogEntity _toEntity(db.FeedingLog log) => FeedingLogEntity(
        id: log.id,
        babyId: log.babyId,
        type: FeedingType.fromString(log.type),
        startTime: log.startTime,
        endTime: log.endTime,
        durationMinutes: log.durationMinutes,
        side: BreastSide.fromString(log.side),
        amountMl: log.amountMl,
        amountOz: log.amountOz,
        notes: log.notes,
        createdAt: log.createdAt,
        modifiedAt: log.modifiedAt,
      );

  static db.FeedingLogsCompanion _toCompanion(FeedingLogEntity log) =>
      db.FeedingLogsCompanion(
        id: Value(log.id),
        babyId: Value(log.babyId),
        type: Value(log.type.name),
        startTime: Value(log.startTime),
        endTime: Value(log.endTime),
        durationMinutes: Value(log.durationMinutes),
        side: Value(log.side?.name),
        amountMl: Value(log.amountMl),
        amountOz: Value(log.amountOz),
        notes: Value(log.notes),
        createdAt: Value(log.createdAt),
        modifiedAt: Value(log.modifiedAt),
      );
}
