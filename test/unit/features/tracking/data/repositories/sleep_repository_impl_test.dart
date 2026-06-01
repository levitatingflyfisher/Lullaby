import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/tracking/data/repositories/sleep_repository_impl.dart';
import 'package:lullaby/features/tracking/domain/entities/sleep_log.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late SleepRepositoryImpl repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SleepRepositoryImpl(db.sleepDao);
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  SleepLogEntity makeLog({String id = 's1', DateTime? startTime}) =>
      SleepLogEntity(
        id: id,
        babyId: 'baby1',
        startTime: startTime ?? now,
        type: SleepType.nap,
        createdAt: now,
        modifiedAt: now,
      );

  group('getLastSleep', () {
    test('returns null when no logs exist', () async {
      final result = await repo.getLastSleep('baby1');
      expect(result, isA<Success<SleepLogEntity?>>());
      expect((result as Success<SleepLogEntity?>).value, isNull);
    });

    test('returns the most recent log', () async {
      await repo.createSleep(
          makeLog(id: 's1', startTime: now.subtract(const Duration(hours: 2))));
      await repo.createSleep(makeLog(id: 's2', startTime: now));

      final result = await repo.getLastSleep('baby1');
      expect(result, isA<Success<SleepLogEntity?>>());
      final log = (result as Success<SleepLogEntity?>).value;
      expect(log, isNotNull);
      expect(log!.id, 's2');
    });

    test('ignores logs for other babies', () async {
      await db.babyDao.insertBaby(BabiesCompanion.insert(
        id: 'baby2',
        name: 'Other Baby',
        dateOfBirth: DateTime(2024, 12, 1),
        createdAt: now,
        modifiedAt: now,
      ));
      await repo.createSleep(makeLog(id: 's1').copyWith(babyId: 'baby2'));

      final result = await repo.getLastSleep('baby1');
      expect((result as Success<SleepLogEntity?>).value, isNull);
    });
  });
}
