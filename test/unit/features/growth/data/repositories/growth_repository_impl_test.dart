import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/growth/data/repositories/growth_repository_impl.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late GrowthRepositoryImpl repo;
  final now = DateTime(2025, 6, 15);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GrowthRepositoryImpl(db.growthDao);
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  GrowthRecordEntity makeEntity({
    String id = 'r1',
    DateTime? measuredAt,
    double? weightKg = 5.5,
    double? heightCm = 60.0,
    double? headCircumferenceCm,
    String? notes,
  }) =>
      GrowthRecordEntity(
        id: id,
        babyId: 'baby1',
        measuredAt: measuredAt ?? now,
        weightKg: weightKg,
        heightCm: heightCm,
        headCircumferenceCm: headCircumferenceCm,
        notes: notes,
        createdAt: now,
        modifiedAt: now,
      );

  group('GrowthRepositoryImpl', () {
    test('createGrowthRecord and getAllForBaby', () async {
      final entity = makeEntity();
      final createResult = await repo.createGrowthRecord(entity);
      expect(createResult, isA<Success>());

      final getResult = await repo.getAllForBaby('baby1');
      expect(getResult, isA<Success<List<GrowthRecordEntity>>>());
      final records = (getResult as Success<List<GrowthRecordEntity>>).value;
      expect(records, hasLength(1));
      expect(records.first.weightKg, 5.5);
      expect(records.first.heightCm, 60.0);
    });

    test('getLatest returns most recent record', () async {
      final earlier = now.subtract(const Duration(hours: 2));
      await repo.createGrowthRecord(makeEntity(id: 'r1', measuredAt: earlier));
      await repo.createGrowthRecord(makeEntity(id: 'r2', measuredAt: now));

      final result = await repo.getLatest('baby1');
      expect(result, isA<Success<GrowthRecordEntity?>>());
      final latest = (result as Success<GrowthRecordEntity?>).value;
      expect(latest?.id, 'r2');
    });

    test('getLatest returns null when no records', () async {
      final result = await repo.getLatest('baby1');
      expect(result, isA<Success<GrowthRecordEntity?>>());
      final latest = (result as Success<GrowthRecordEntity?>).value;
      expect(latest, isNull);
    });

    test('getInRange returns records within range', () async {
      final before = now.subtract(const Duration(days: 3));
      await repo.createGrowthRecord(makeEntity(id: 'r1', measuredAt: before));
      await repo.createGrowthRecord(makeEntity(id: 'r2', measuredAt: now));

      final result = await repo.getInRange(
          'baby1', now.subtract(const Duration(hours: 1)), now.add(const Duration(hours: 1)));
      expect(result, isA<Success<List<GrowthRecordEntity>>>());
      final records = (result as Success<List<GrowthRecordEntity>>).value;
      expect(records, hasLength(1));
      expect(records.first.id, 'r2');
    });

    test('updateGrowthRecord modifies entity', () async {
      await repo.createGrowthRecord(makeEntity());
      final updated = makeEntity().copyWith(weightKg: () => 7.0);
      final result = await repo.updateGrowthRecord(updated);
      expect(result, isA<Success>());

      final getResult = await repo.getAllForBaby('baby1');
      final records = (getResult as Success<List<GrowthRecordEntity>>).value;
      expect(records.first.weightKg, 7.0);
    });

    test('deleteGrowthRecord removes entity', () async {
      await repo.createGrowthRecord(makeEntity());
      final result = await repo.deleteGrowthRecord('r1');
      expect(result, isA<Success>());

      final getResult = await repo.getAllForBaby('baby1');
      final records = (getResult as Success<List<GrowthRecordEntity>>).value;
      expect(records, isEmpty);
    });

    test('maps all nullable fields correctly', () async {
      final entity = GrowthRecordEntity(
        id: 'r_full',
        babyId: 'baby1',
        measuredAt: now,
        weightKg: 5.5,
        heightCm: 60.0,
        headCircumferenceCm: 40.5,
        notes: 'Doctor visit',
        createdAt: now,
        modifiedAt: now,
      );
      await repo.createGrowthRecord(entity);

      final result = await repo.getAllForBaby('baby1');
      final record = (result as Success<List<GrowthRecordEntity>>).value.first;
      expect(record.weightKg, 5.5);
      expect(record.heightCm, 60.0);
      expect(record.headCircumferenceCm, 40.5);
      expect(record.notes, 'Doctor visit');
    });

    test('watchAllForBaby emits entity stream', () async {
      await repo.createGrowthRecord(makeEntity());
      final stream = repo.watchAllForBaby('baby1');
      final records = await stream.first;
      expect(records, hasLength(1));
      expect(records.first.babyId, 'baby1');
    });
  });
}
