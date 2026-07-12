import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late LullabyBackupSerializer serializer;

  final now = DateTime(2026, 4, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    serializer = LullabyBackupSerializer(db);
  });

  tearDown(() => db.close());

  Future<void> seedData() async {
    await db.into(db.babies).insert(BabiesCompanion.insert(
          id: 'b1',
          name: 'Alice',
          dateOfBirth: DateTime(2025, 6, 1),
          gender: const Value('female'),
          createdAt: now,
          modifiedAt: now,
        ));

    await db.into(db.feedingLogs).insert(FeedingLogsCompanion.insert(
          id: 'f1',
          babyId: 'b1',
          type: 'breast',
          startTime: now,
          side: const Value('left'),
          durationMinutes: const Value(15),
          createdAt: now,
          modifiedAt: now,
        ));

    await db.into(db.sleepLogs).insert(SleepLogsCompanion.insert(
          id: 's1',
          babyId: 'b1',
          startTime: now,
          type: 'nap',
          location: const Value('crib'),
          createdAt: now,
          modifiedAt: now,
        ));

    await db.into(db.diaperLogs).insert(DiaperLogsCompanion.insert(
          id: 'd1',
          babyId: 'b1',
          time: now,
          type: 'wet',
          createdAt: now,
          modifiedAt: now,
        ));

    await db.into(db.growthRecords).insert(GrowthRecordsCompanion.insert(
          id: 'g1',
          babyId: 'b1',
          measuredAt: now,
          weightKg: const Value(7.5),
          heightCm: const Value(65.0),
          createdAt: now,
          modifiedAt: now,
        ));

    await db.into(db.medicineLogs).insert(MedicineLogsCompanion.insert(
          id: 'm1',
          babyId: 'b1',
          medicineName: 'Tylenol',
          dosage: const Value(2.5),
          dosageUnit: const Value('mL'),
          administeredAt: now,
          createdAt: now,
          modifiedAt: now,
        ));

    await db.into(db.vaccineRecords).insert(VaccineRecordsCompanion.insert(
          id: 'v1',
          babyId: 'b1',
          vaccineName: 'DTaP',
          doseNumber: const Value(1),
          administeredDate: Value(now),
          createdAt: now,
          modifiedAt: now,
        ));
  }

  group('BackupSerializer', () {
    test('dumpAll includes schemaVersion and all tables', () async {
      await seedData();
      final bytes = await serializer.dumpAll();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(json['schemaVersion'], equals(db.schemaVersion));
      expect(json['exportedAt'], isNotNull);

      final tables = json['tables'] as Map<String, dynamic>;
      expect(tables['babies'], hasLength(1));
      expect(tables['feedingLogs'], hasLength(1));
      expect(tables['sleepLogs'], hasLength(1));
      expect(tables['diaperLogs'], hasLength(1));
      expect(tables['growthRecords'], hasLength(1));
      expect(tables['medicineLogs'], hasLength(1));
      expect(tables['vaccineRecords'], hasLength(1));

      // Spot-check baby data round-trips through JSON
      final baby = tables['babies'][0] as Map<String, dynamic>;
      expect(baby['name'], equals('Alice'));
      expect(baby['gender'], equals('female'));
    });

    test('dumpAll on empty DB produces valid payload with zero rows', () async {
      final bytes = await serializer.dumpAll();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(json['schemaVersion'], equals(db.schemaVersion));
      final tables = json['tables'] as Map<String, dynamic>;
      for (final entry in tables.entries) {
        expect(entry.value, isEmpty, reason: '${entry.key} should be empty');
      }
    });

    test('restoreAll round-trips all data', () async {
      await seedData();
      final bytes = await serializer.dumpAll();

      // Wipe and restore into same DB
      await serializer.restoreAll(bytes);

      // Verify all data survived
      final babies = await db.select(db.babies).get();
      expect(babies, hasLength(1));
      expect(babies.first.name, equals('Alice'));
      expect(babies.first.gender, equals('female'));

      final feedings = await db.select(db.feedingLogs).get();
      expect(feedings, hasLength(1));
      expect(feedings.first.type, equals('breast'));
      expect(feedings.first.side, equals('left'));
      expect(feedings.first.durationMinutes, equals(15));

      final sleeps = await db.select(db.sleepLogs).get();
      expect(sleeps, hasLength(1));
      expect(sleeps.first.type, equals('nap'));
      expect(sleeps.first.location, equals('crib'));

      final diapers = await db.select(db.diaperLogs).get();
      expect(diapers, hasLength(1));
      expect(diapers.first.type, equals('wet'));

      final growth = await db.select(db.growthRecords).get();
      expect(growth, hasLength(1));
      expect(growth.first.weightKg, equals(7.5));
      expect(growth.first.heightCm, equals(65.0));

      final meds = await db.select(db.medicineLogs).get();
      expect(meds, hasLength(1));
      expect(meds.first.medicineName, equals('Tylenol'));
      expect(meds.first.dosage, equals(2.5));

      final vaccines = await db.select(db.vaccineRecords).get();
      expect(vaccines, hasLength(1));
      expect(vaccines.first.vaccineName, equals('DTaP'));
      expect(vaccines.first.doseNumber, equals(1));
    });

    test('restoreAll wipes existing data before inserting', () async {
      // Seed initial data
      await seedData();

      // Create a dump with different data
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final serializer2 = LullabyBackupSerializer(db2);
      await db2.into(db2.babies).insert(BabiesCompanion.insert(
            id: 'b2',
            name: 'Bob',
            dateOfBirth: DateTime(2025, 1, 1),
            createdAt: now,
            modifiedAt: now,
          ));
      final otherDump = await serializer2.dumpAll();
      await db2.close();

      // Restore over existing data
      await serializer.restoreAll(otherDump);

      final babies = await db.select(db.babies).get();
      expect(babies, hasLength(1));
      expect(babies.first.name, equals('Bob'));

      // Old data should be gone
      final feedings = await db.select(db.feedingLogs).get();
      expect(feedings, isEmpty);
    });

    test('restoreAll rejects future schema version', () async {
      final payload = jsonEncode({
        'schemaVersion': 999,
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': {
          'babies': <dynamic>[],
          'feedingLogs': <dynamic>[],
          'sleepLogs': <dynamic>[],
          'diaperLogs': <dynamic>[],
          'growthRecords': <dynamic>[],
          'medicineLogs': <dynamic>[],
          'vaccineRecords': <dynamic>[],
        },
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<BackupSchemaException>()),
      );
    });

    test('restoreAll rejects missing schemaVersion', () async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'tables': <String, dynamic>{},
      })));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('restoreAll rejects missing tables key', () async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'schemaVersion': 3,
      })));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('restoreAll handles missing table gracefully (old backup)', () async {
      // A v2 backup might not have medicineLogs/vaccineRecords
      final payload = jsonEncode({
        'schemaVersion': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': {
          'babies': <dynamic>[],
          'feedingLogs': <dynamic>[],
          'sleepLogs': <dynamic>[],
          'diaperLogs': <dynamic>[],
          'growthRecords': <dynamic>[],
          // medicineLogs and vaccineRecords intentionally absent
        },
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));

      // Should not throw — missing tables just mean zero rows
      await serializer.restoreAll(bytes);

      final meds = await db.select(db.medicineLogs).get();
      expect(meds, isEmpty);
    });
  });
}
