import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/babies/data/repositories/baby_repository_impl.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late BabyRepositoryImpl repo;
  final now = DateTime(2025, 6, 15);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BabyRepositoryImpl(db.babyDao);
  });

  tearDown(() => db.close());

  BabyEntity makeBabyEntity({String id = '1', String name = 'Alice'}) =>
      BabyEntity(
        id: id,
        name: name,
        dateOfBirth: DateTime(2024, 12, 1),
        gender: Gender.female,
        isActive: true,
        createdAt: now,
        modifiedAt: now,
      );

  group('BabyRepositoryImpl', () {
    test('createBaby and getBabyById', () async {
      final baby = makeBabyEntity();
      final createResult = await repo.createBaby(baby);
      expect(createResult, isA<Success>());

      final getResult = await repo.getBabyById('1');
      expect(getResult, isA<Success<BabyEntity>>());
      final fetched = (getResult as Success<BabyEntity>).value;
      expect(fetched.name, 'Alice');
      expect(fetched.gender, Gender.female);
    });

    test('getAllBabies returns all', () async {
      await repo.createBaby(makeBabyEntity(id: '1', name: 'Alice'));
      await repo.createBaby(makeBabyEntity(id: '2', name: 'Bob'));

      final result = await repo.getAllBabies();
      expect(result, isA<Success<List<BabyEntity>>>());
      final babies = (result as Success<List<BabyEntity>>).value;
      expect(babies, hasLength(2));
    });

    test('getBabyById returns NotFoundFailure for missing', () async {
      final result = await repo.getBabyById('nonexistent');
      expect(result, isA<Err>());
    });

    test('updateBaby modifies entity', () async {
      await repo.createBaby(makeBabyEntity());
      final updated = makeBabyEntity().copyWith(name: 'Alice Updated');
      final result = await repo.updateBaby(updated);
      expect(result, isA<Success>());

      final fetched = await repo.getBabyById('1');
      expect((fetched as Success<BabyEntity>).value.name, 'Alice Updated');
    });

    test('deleteBaby removes entity', () async {
      await repo.createBaby(makeBabyEntity());
      await repo.deleteBaby('1');
      final result = await repo.getBabyById('1');
      expect(result, isA<Err>());
    });

    test('watchActiveBaby emits entity', () async {
      await repo.createBaby(makeBabyEntity());
      final stream = repo.watchActiveBaby();
      final baby = await stream.first;
      expect(baby, isNotNull);
      expect(baby!.name, 'Alice');
    });

    test('maps gender correctly', () async {
      await repo.createBaby(makeBabyEntity());
      final result = await repo.getBabyById('1');
      final baby = (result as Success<BabyEntity>).value;
      expect(baby.gender, Gender.female);
    });

    test('handles null gender', () async {
      final baby = BabyEntity(
        id: '3',
        name: 'No Gender',
        dateOfBirth: DateTime(2024, 12, 1),
        isActive: true,
        createdAt: now,
        modifiedAt: now,
      );
      await repo.createBaby(baby);
      final result = await repo.getBabyById('3');
      final fetched = (result as Success<BabyEntity>).value;
      expect(fetched.gender, isNull);
    });
  });
}
