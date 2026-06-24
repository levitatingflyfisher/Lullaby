import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/tracking/data/repositories/feeding_repository_impl.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late FeedingRepositoryImpl repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FeedingRepositoryImpl(db.feedingDao);
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  FeedingLogEntity makeLog({String id = 'f1'}) => FeedingLogEntity(
        id: id,
        babyId: 'baby1',
        type: FeedingType.breast,
        startTime: now,
        side: BreastSide.left,
        createdAt: now,
        modifiedAt: now,
      );

  group('FeedingRepositoryImpl', () {
    test('create and getAll', () async {
      await repo.createFeeding(makeLog());
      final result = await repo.getAllForBaby('baby1');
      expect(result, isA<Success<List<FeedingLogEntity>>>());
      final logs = (result as Success<List<FeedingLogEntity>>).value;
      expect(logs, hasLength(1));
      expect(logs.first.type, FeedingType.breast);
      expect(logs.first.side, BreastSide.left);
    });

    test('getLastFeeding returns most recent', () async {
      await repo.createFeeding(
          makeLog(id: 'f1').copyWith(
              startTime: now.subtract(const Duration(hours: 2))));
      await repo.createFeeding(makeLog(id: 'f2'));

      final result = await repo.getLastFeeding('baby1');
      expect(result, isA<Success<FeedingLogEntity?>>());
      final log = (result as Success<FeedingLogEntity?>).value;
      expect(log, isNotNull);
      expect(log!.id, 'f2');
    });

    test('updateFeeding modifies entry', () async {
      await repo.createFeeding(makeLog());
      final updated = makeLog().copyWith(type: FeedingType.bottle);
      await repo.updateFeeding(updated);

      final result = await repo.getAllForBaby('baby1');
      final logs = (result as Success<List<FeedingLogEntity>>).value;
      expect(logs.first.type, FeedingType.bottle);
    });

    test('deleteFeeding removes entry', () async {
      await repo.createFeeding(makeLog());
      await repo.deleteFeeding('f1');
      final result = await repo.getAllForBaby('baby1');
      expect((result as Success<List<FeedingLogEntity>>).value, isEmpty);
    });

    test('maps FeedingType correctly', () async {
      await repo.createFeeding(makeLog().copyWith(type: FeedingType.solid));
      final result = await repo.getAllForBaby('baby1');
      final logs = (result as Success<List<FeedingLogEntity>>).value;
      expect(logs.first.type, FeedingType.solid);
    });

    test('maps BreastSide correctly', () async {
      await repo.createFeeding(
          makeLog().copyWith(side: () => BreastSide.both));
      final result = await repo.getAllForBaby('baby1');
      final logs = (result as Success<List<FeedingLogEntity>>).value;
      expect(logs.first.side, BreastSide.both);
    });
  });
}
