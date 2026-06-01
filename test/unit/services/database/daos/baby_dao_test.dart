import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:lullaby/services/database/daos/baby_dao.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late BabyDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.babyDao;
  });

  tearDown(() => db.close());

  final now = DateTime(2025, 6, 15);

  BabiesCompanion makeBaby({String id = '1', String name = 'Alice'}) =>
      BabiesCompanion.insert(
        id: id,
        name: name,
        dateOfBirth: DateTime(2024, 12, 1),
        createdAt: now,
        modifiedAt: now,
      );

  group('BabyDao', () {
    test('insertBaby and getBabyById', () async {
      await dao.insertBaby(makeBaby());
      final baby = await dao.getBabyById('1');
      expect(baby, isNotNull);
      expect(baby!.name, 'Alice');
    });

    test('getAllBabies returns all', () async {
      await dao.insertBaby(makeBaby(id: '1', name: 'Alice'));
      await dao.insertBaby(makeBaby(id: '2', name: 'Bob'));
      final babies = await dao.getAllBabies();
      expect(babies, hasLength(2));
    });

    test('getBabyById returns null for non-existent', () async {
      final baby = await dao.getBabyById('nonexistent');
      expect(baby, isNull);
    });

    test('updateBaby modifies existing', () async {
      await dao.insertBaby(makeBaby());
      final updated = BabiesCompanion(
        id: const Value('1'),
        name: const Value('Alice Updated'),
        dateOfBirth: Value(DateTime(2024, 12, 1)),
        isActive: const Value(true),
        createdAt: Value(now),
        modifiedAt: Value(now),
      );
      await dao.updateBaby(updated);
      final baby = await dao.getBabyById('1');
      expect(baby!.name, 'Alice Updated');
    });

    test('deleteBaby removes entry', () async {
      await dao.insertBaby(makeBaby());
      await dao.deleteBaby('1');
      final baby = await dao.getBabyById('1');
      expect(baby, isNull);
    });

    test('watchActiveBaby emits active baby', () async {
      await dao.insertBaby(makeBaby());
      final stream = dao.watchActiveBaby();
      final baby = await stream.first;
      expect(baby, isNotNull);
      expect(baby!.name, 'Alice');
    });

    test('watchAllBabies emits updates', () async {
      final stream = dao.watchAllBabies();
      // First emission is empty
      expect(await stream.first, isEmpty);
    });

    test('deleteBaby cascades to child rows', () async {
      await dao.insertBaby(makeBaby());
      await db.into(db.feedingLogs).insert(FeedingLogsCompanion.insert(
            id: 'f1',
            babyId: '1',
            type: 'bottle',
            startTime: now,
            createdAt: now,
            modifiedAt: now,
          ));

      await dao.deleteBaby('1');

      expect(await db.select(db.feedingLogs).get(), isEmpty);
      expect(await dao.getBabyById('1'), isNull);
    });

    test('deleteBaby promotes another baby when the active one is removed',
        () async {
      await dao.insertBaby(makeBaby(id: '1', name: 'Alice'));
      await dao.insertBabyAsActive(makeBaby(id: '2', name: 'Bob')); // 2 active

      await dao.deleteBaby('2');

      final active =
          (await dao.getAllBabies()).where((b) => b.isActive).map((b) => b.id);
      expect(active, ['1']); // Alice promoted so the app isn't left babyless
    });

    test('insertBabyAsActive demotes the previously active baby', () async {
      await dao.insertBaby(makeBaby(id: '1', name: 'Alice'));
      await dao.insertBabyAsActive(makeBaby(id: '2', name: 'Bob'));

      final active =
          (await dao.getAllBabies()).where((b) => b.isActive).toList();
      expect(active, hasLength(1));
      expect(active.single.id, '2');
    });

    test('setActiveBaby leaves exactly one active baby', () async {
      // Both inserted active (no DB-level uniqueness), then normalized.
      await dao.insertBaby(makeBaby(id: '1', name: 'Alice'));
      await dao.insertBaby(makeBaby(id: '2', name: 'Bob'));

      await dao.setActiveBaby('1');

      final active =
          (await dao.getAllBabies()).where((b) => b.isActive).map((b) => b.id);
      expect(active, ['1']);
    });

    test('watchActiveBaby emits one baby even if two are active', () async {
      await dao.insertBaby(makeBaby(id: '1', name: 'Alice'));
      await dao.insertBaby(makeBaby(id: '2', name: 'Bob'));

      // Must not push a StateError into the stream (would brick the dashboard).
      expect(await dao.watchActiveBaby().first, isNotNull);
    });
  });
}
