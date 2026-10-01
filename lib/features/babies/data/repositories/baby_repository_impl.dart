import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/database/daos/baby_dao.dart';
import '../../domain/entities/baby.dart';
import '../../../sync/data/lullaby_records.dart';
import '../../../sync/data/record_projection.dart';
import '../../../sync/data/record_writer.dart';
import '../../domain/repositories/baby_repository.dart';

class BabyRepositoryImpl implements BabyRepository {
  BabyRepositoryImpl(this._dao, [RecordWriter? writer])
      : _writer = writer ??
            DirectRecordWriter(RecordProjection(_dao.attachedDatabase));
  final BabyDao _dao;

  /// Synced fields go through here (docs/adr/0007-household-sync.md). Which
  /// baby is selected and the photo path stay on this phone and are written
  /// with [_dao] directly.
  final RecordWriter _writer;

  @override
  Future<Result<List<BabyEntity>>> getAllBabies() async {
    try {
      final babies = await _dao.getAllBabies();
      return Success(babies.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<List<BabyEntity>> watchAllBabies() =>
      _dao.watchAllBabies().map((list) => list.map(_toEntity).toList());

  @override
  Future<Result<BabyEntity>> getBabyById(String id) async {
    try {
      final baby = await _dao.getBabyById(id);
      if (baby == null) return const Err(NotFoundFailure());
      return Success(_toEntity(baby));
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<BabyEntity?> watchActiveBaby() =>
      _dao.watchActiveBaby().map((b) => b == null ? null : _toEntity(b));

  @override
  Future<Result<void>> createBaby(BabyEntity baby) async {
    try {
      await _writer.put(
          babiesSpec, baby.id, companionFields(babiesSpec, _toCompanion(baby)));
      // The new baby becomes the sole selected one on this phone.
      await _dao.setActiveBaby(baby.id);
      await _dao.setPhotoPath(baby.id, baby.photoPath);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> setActiveBaby(String id) async {
    try {
      await _dao.setActiveBaby(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateBaby(BabyEntity baby) async {
    try {
      await _writer.update(
          babiesSpec, baby.id, companionFields(babiesSpec, _toCompanion(baby)));
      await _dao.setPhotoPath(baby.id, baby.photoPath);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBaby(String id) async {
    try {
      // Hides the baby's records with it, on every synced phone.
      await _writer.delete(babiesSpec, id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  static BabyEntity _toEntity(db.Baby baby) => BabyEntity(
        id: baby.id,
        name: baby.name,
        dateOfBirth: baby.dateOfBirth,
        gender: Gender.fromString(baby.gender),
        photoPath: baby.photoPath,
        isActive: baby.isActive,
        createdAt: baby.createdAt,
        modifiedAt: baby.modifiedAt,
      );

  static db.BabiesCompanion _toCompanion(BabyEntity baby) => db.BabiesCompanion(
        id: Value(baby.id),
        name: Value(baby.name),
        dateOfBirth: Value(baby.dateOfBirth),
        gender: Value(baby.gender?.name),
        photoPath: Value(baby.photoPath),
        isActive: Value(baby.isActive),
        createdAt: Value(baby.createdAt),
        modifiedAt: Value(baby.modifiedAt),
      );
}
