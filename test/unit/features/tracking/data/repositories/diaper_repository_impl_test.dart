import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/tracking/data/repositories/diaper_repository_impl.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late DiaperRepositoryImpl repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DiaperRepositoryImpl(db.diaperDao);
    await db.babyDao.insertBaby(BabiesCompanion.insert(
      id: 'baby1',
      name: 'Test Baby',
      dateOfBirth: DateTime(2024, 12, 1),
      createdAt: now,
      modifiedAt: now,
    ));
  });

  tearDown(() => db.close());

  DiaperLogEntity makeLog({String id = 'd1', DateTime? time}) =>
      DiaperLogEntity(
        id: id,
        babyId: 'baby1',
        time: time ?? now,
        type: DiaperType.wet,
        createdAt: now,
        modifiedAt: now,
      );

  group('getLastDiaper', () {
    test('returns null when no logs exist', () async {
      final result = await repo.getLastDiaper('baby1');
      expect(result, isA<Success<DiaperLogEntity?>>());
      expect((result as Success<DiaperLogEntity?>).value, isNull);
    });

    test('returns the most recent log', () async {
      await repo.createDiaper(
          makeLog(id: 'd1', time: now.subtract(const Duration(hours: 2))));
      await repo.createDiaper(makeLog(id: 'd2', time: now));

      final result = await repo.getLastDiaper('baby1');
      expect(result, isA<Success<DiaperLogEntity?>>());
      final log = (result as Success<DiaperLogEntity?>).value;
      expect(log, isNotNull);
      expect(log!.id, 'd2');
    });

    test('ignores logs for other babies', () async {
      await db.babyDao.insertBaby(BabiesCompanion.insert(
        id: 'baby2',
        name: 'Other Baby',
        dateOfBirth: DateTime(2024, 12, 1),
        createdAt: now,
        modifiedAt: now,
      ));
      await repo.createDiaper(makeLog(id: 'd1').copyWith(babyId: 'baby2'));

      final result = await repo.getLastDiaper('baby1');
      expect((result as Success<DiaperLogEntity?>).value, isNull);
    });
  });
}
