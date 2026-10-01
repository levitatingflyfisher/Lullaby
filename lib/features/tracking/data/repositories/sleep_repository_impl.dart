import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/database/daos/sleep_dao.dart';
import '../../domain/entities/sleep_log.dart';
import '../../../sync/data/lullaby_records.dart';
import '../../../sync/data/record_projection.dart';
import '../../../sync/data/record_writer.dart';
import '../../domain/repositories/sleep_repository.dart';

class SleepRepositoryImpl implements SleepRepository {
  SleepRepositoryImpl(this._dao, [RecordWriter? writer])
      : _writer = writer ?? DirectRecordWriter(RecordProjection(_dao.attachedDatabase));
  final SleepDao _dao;

  /// Every change goes through here, so it reaches the household's log when
  /// sync is on (docs/adr/0007-household-sync.md). Reads stay on [_dao].
  final RecordWriter _writer;

  @override
  Future<Result<List<SleepLogEntity>>> getAllForBaby(String babyId) async {
    try {
      final logs = await _dao.getAllForBaby(babyId);
      return Success(logs.map(_toEntity).toList());
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Stream<List<SleepLogEntity>> watchAllForBaby(String babyId) =>
      _dao.watchAllForBaby(babyId).map((l) => l.map(_toEntity).toList());

  @override
  Future<Result<SleepLogEntity?>> getActiveSleep(String babyId) async {
    try {
      final log = await _dao.getActiveSleep(babyId);
      return Success(log == null ? null : _toEntity(log));
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Stream<SleepLogEntity?> watchActiveSleep(String babyId) =>
      _dao.watchActiveSleep(babyId).map((l) => l == null ? null : _toEntity(l));

  @override
  Future<Result<SleepLogEntity?>> getLastSleep(String babyId) async {
    try {
      final log = await _dao.getLastSleep(babyId);
      return Success(log == null ? null : _toEntity(log));
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<List<SleepLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    try {
      final logs = await _dao.getInRange(babyId, start, end);
      return Success(logs.map(_toEntity).toList());
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> createSleep(SleepLogEntity log) async {
    try {
      await _writer.put(sleepSpec, log.id, companionFields(sleepSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> updateSleep(SleepLogEntity log) async {
    try {
      await _writer.update(sleepSpec, log.id, companionFields(sleepSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> deleteSleep(String id) async {
    try {
      await _writer.delete(sleepSpec, id);
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  @override
  Future<Result<void>> restoreSleep(SleepLogEntity log) async {
    try {
      await _writer.restore(sleepSpec, log.id, companionFields(sleepSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e, st) {
      return Err(DatabaseFailure.from(e, st));
    }
  }

  static SleepLogEntity _toEntity(db.SleepLog log) => SleepLogEntity(
        id: log.id,
        babyId: log.babyId,
        startTime: log.startTime,
        endTime: log.endTime,
        durationMinutes: log.durationMinutes,
        type: SleepType.fromString(log.type),
        location: SleepLocation.fromString(log.location),
        notes: log.notes,
        createdAt: log.createdAt,
        modifiedAt: log.modifiedAt,
      );

  static db.SleepLogsCompanion _toCompanion(SleepLogEntity log) =>
      db.SleepLogsCompanion(
        id: Value(log.id),
        babyId: Value(log.babyId),
        startTime: Value(log.startTime),
        endTime: Value(log.endTime),
        durationMinutes: Value(log.durationMinutes),
        type: Value(log.type.name),
        location: Value(log.location?.name),
        notes: Value(log.notes),
        createdAt: Value(log.createdAt),
        modifiedAt: Value(log.modifiedAt),
      );
}
