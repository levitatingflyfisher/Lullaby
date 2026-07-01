import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../../test_setup.dart';

/// Lullaby's own serializer round-tripping through the real EnvelopeCipher +
/// the package BackupRepository, bound to Lullaby's legacy AEAD context
/// (SANCTUARY-BRIEF §2.1, §2.3). This is the behaviour-preservation net for the
/// re-wire onto sanctuary_backup_ui.
const _ghostContext = 'ghost-backup/v1';

Uint8List _deterministicKey(int seed) {
  final rng = Random(seed);
  return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
}

void main() {
  ensureSqlite3();

  final cipher = EnvelopeCipher();
  final key = _deterministicKey(1);

  late AppDatabase db;
  late BackupRepository repo;
  final now = DateTime(2026, 4, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BackupRepository(LullabyBackupSerializer(db), cipher,
        aadContext: _ghostContext);
  });

  tearDown(() => db.close());

  Future<void> seedBaby() async {
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
          type: 'bottle',
          startTime: now,
          amountOz: const Value(4.0),
          createdAt: now,
          modifiedAt: now,
        ));
  }

  group('BackupRepository (Lullaby serializer, ghost-backup/v1)', () {
    test('export produces OHBK blob', () async {
      await seedBaby();
      final blob = await repo.export(key);

      // OHBK magic bytes
      expect(blob.sublist(0, 4), equals([0x4F, 0x48, 0x42, 0x4B]));
    });

    test('export → restore round-trips all data', () async {
      await seedBaby();
      final blob = await repo.export(key);

      // Restore into a fresh DB
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final repo2 = BackupRepository(LullabyBackupSerializer(db2), cipher,
          aadContext: _ghostContext);
      await repo2.restore(blob, key);

      final babies = await db2.select(db2.babies).get();
      expect(babies, hasLength(1));
      expect(babies.first.name, equals('Alice'));

      final feedings = await db2.select(db2.feedingLogs).get();
      expect(feedings, hasLength(1));
      expect(feedings.first.amountOz, equals(4.0));

      await db2.close();
    });

    test('wrong key throws CryptoException', () async {
      await seedBaby();
      final blob = await repo.export(key);

      final wrongKey = _deterministicKey(2);
      expect(
        () => repo.restore(blob, wrongKey),
        throwsA(isA<CryptoException>()),
      );
    });

    test('a blob from a different context cannot be restored', () async {
      // §2.3: the AEAD context binds the blob — Lullaby's ghost-backup/v1 blob
      // must not open under any other app's context.
      await seedBaby();
      final blob = await repo.export(key);

      final otherRepo = BackupRepository(LullabyBackupSerializer(db), cipher,
          aadContext: 'lullaby-backup/v1');
      expect(
        () => otherRepo.restore(blob, key),
        throwsA(isA<CryptoException>()),
      );
    });

    test('truncated blob throws BackupFormatException', () async {
      await seedBaby();
      final blob = await repo.export(key);

      final truncated = Uint8List.fromList(blob.sublist(0, 10));
      expect(
        () => repo.restore(truncated, key),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('corrupted ciphertext throws CryptoException', () async {
      await seedBaby();
      final blob = await repo.export(key);

      // 34-byte prefix (4 magic + 1 version + 1 suite + 12 nonce + 16 MAC).
      // Flip a byte inside the ciphertext region.
      final corrupted = Uint8List.fromList(blob);
      corrupted[35] ^= 0xFF;
      expect(
        () => repo.restore(corrupted, key),
        throwsA(isA<CryptoException>()),
      );
    });
  });
}
