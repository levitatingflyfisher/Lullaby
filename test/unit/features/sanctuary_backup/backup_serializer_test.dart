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

  group('v2 retention-spec envelope (additive, old readers unaffected)', () {
    test(
        'dumpAll KEEPS the legacy shape (schemaVersion/exportedAt/tables at '
        'top level) and ADDS app + createdAt', () async {
      await seedData();
      final bytes = await serializer.dumpAll();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      // Legacy keys old shipped readers depend on — MUST stay top-level.
      expect(json['schemaVersion'], db.schemaVersion);
      expect(json['exportedAt'], isA<String>());
      expect(json['tables'], isA<Map<String, dynamic>>());
      // New additive keys (ignored by old readers, used by v2 preview).
      expect(json['app'], 'lullaby');
      expect(DateTime.parse(json['createdAt'] as String).isUtc, isTrue);
    });

    test('a LEGACY backup with NO app key still restores', () async {
      await seedData();
      final bytes = await serializer.dumpAll();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      json.remove('app');
      json.remove('createdAt'); // exactly what shipped Lullaby wrote
      final legacy = Uint8List.fromList(utf8.encode(jsonEncode(json)));

      // restoreAll wipes-and-replaces itself; a legacy envelope must drive
      // that full path successfully.
      await serializer.restoreAll(legacy);
      expect(await db.select(db.babies).get(), hasLength(1));
      expect(await db.select(db.feedingLogs).get(), hasLength(1));
    });

    test('a backup carrying a DIFFERENT app id now rejects (new protection)',
        () async {
      final foreign = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'furrow',
        'schemaVersion': 1,
        'tables': <String, Object?>{},
      })));
      expect(() => serializer.restoreAll(foreign),
          throwsA(isA<FormatException>()));
    });

    test(
        'describeBackup dry-run parses: counts rows, rejects future schema, '
        'never writes', () async {
      await seedData();
      final bytes = await serializer.dumpAll();

      expect(serializer, isA<PreviewableBackupSerializer>());
      final manifest = await serializer.describeBackup(bytes);
      expect(manifest.appId, 'lullaby');
      expect(manifest.tableCounts['babies'], 1);
      expect(manifest.tableCounts['feedingLogs'], 1);
      expect(manifest.createdAt, isNotNull);

      final tooNew = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'lullaby',
        'schemaVersion': 99,
        'tables': <String, Object?>{},
      })));
      expect(() => serializer.describeBackup(tooNew),
          throwsA(isA<BackupSchemaException>()));

      // REVIEW FIX: describe must reject payloads restoreAll would reject —
      // including a missing/non-map tables key.
      final noTables = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'lullaby',
        'schemaVersion': db.schemaVersion,
        'exportedAt': '2026-06-01T10:00:00.000Z',
      })));
      expect(() => serializer.describeBackup(noTables),
          throwsA(isA<FormatException>()));

      expect(await db.select(db.babies).get(), hasLength(1),
          reason: 'describe must never write');
    });
  });
}
