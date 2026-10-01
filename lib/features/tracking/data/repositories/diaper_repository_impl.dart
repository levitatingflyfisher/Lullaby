import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/database/daos/diaper_dao.dart';
import '../../domain/entities/diaper_log.dart';
import '../../../sync/data/lullaby_records.dart';
import '../../../sync/data/record_projection.dart';
import '../../../sync/data/record_writer.dart';
import '../../domain/repositories/diaper_repository.dart';

class DiaperRepositoryImpl implements DiaperRepository {
  DiaperRepositoryImpl(this._dao, [RecordWriter? writer])
      : _writer = writer ?? DirectRecordWriter(RecordProjection(_dao.attachedDatabase));
  final DiaperDao _dao;

  /// Every change goes through here, so it reaches the household's log when
  /// sync is on (docs/adr/0007-household-sync.md). Reads stay on [_dao].
  final RecordWriter _writer;

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
      await _writer.put(diaperSpec, log.id, companionFields(diaperSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateDiaper(DiaperLogEntity log) async {
    try {
      await _writer.update(diaperSpec, log.id, companionFields(diaperSpec, _toCompanion(log)));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteDiaper(String id) async {
    try {
      await _writer.delete(diaperSpec, id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> restoreDiaper(DiaperLogEntity log) async {
    try {
      await _writer.restore(diaperSpec, log.id, companionFields(diaperSpec, _toCompanion(log)));
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
