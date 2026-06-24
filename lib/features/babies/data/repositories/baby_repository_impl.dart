import 'package:drift/drift.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/database/daos/baby_dao.dart';
import '../../domain/entities/baby.dart';
import '../../domain/repositories/baby_repository.dart';

class BabyRepositoryImpl implements BabyRepository {
  BabyRepositoryImpl(this._dao);
  final BabyDao _dao;

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
      // Insert as the sole active baby so the single-active invariant holds.
      await _dao.insertBabyAsActive(_toCompanion(baby));
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
      await _dao.updateBaby(_toCompanion(baby));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBaby(String id) async {
    try {
      await _dao.deleteBaby(id);
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
