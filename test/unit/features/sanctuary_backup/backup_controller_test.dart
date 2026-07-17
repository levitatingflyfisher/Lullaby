import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';

import '../../../test_setup.dart';

/// End-to-end net for the re-wire: Lullaby's real serializer + real crypto,
/// driven through the package's BackupController with Lullaby's actual config
/// (appId 'lullaby', legacy ghost-backup/v1 context). The generic controller
/// behaviour (RestoreOutcome mapping, seed flows) is unit-tested in the package;
/// this proves Lullaby's wiring works against the real sanctuary_auth_core.
const _validPhrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final now = DateTime(2026, 4, 10);

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer makeContainer({
    required AppDatabase database,
    required SecureKeyStore store,
    void Function(Ref ref)? onAfterRestore,
  }) {
    final c = ProviderContainer(overrides: [
      secureKeyStoreProvider.overrideWithValue(store),
      vaultStoreProvider.overrideWithValue(InMemoryVaultStore()),
      cryptoServiceProvider.overrideWithValue(const DefaultCryptoService()),
      backupSerializerProvider
          .overrideWith((ref) => LullabyBackupSerializer(database)),
      sanctuaryBackupConfigProvider.overrideWithValue(
        SanctuaryBackupConfig(
          appId: 'lullaby',
          aadContext: 'ghost-backup/v1',
          appDisplayName: 'Lullaby',
          onAfterRestore: onAfterRestore,
        ),
      ),
      // sanctuaryAppDomainProvider stays at its null default (legacy keys).
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('export → restore round-trips Lullaby data through the controller',
      () async {
    await db.into(db.babies).insert(BabiesCompanion.insert(
          id: 'b1',
          name: 'Alice',
          dateOfBirth: DateTime(2025, 6, 1),
          createdAt: now,
          modifiedAt: now,
        ));

    final src = makeContainer(
      database: db,
      store: InMemorySecureKeyStore(
          mnemonic: _validPhrase, acknowledged: true),
    );
    final result =
        await src.read(backupControllerProvider.notifier).exportBackup();
    expect(result, isNotNull);
    expect(result!.filename,
        matches(RegExp(r'^lullaby-backup-\d{4}-\d{2}-\d{2}\.ohbk$')));
    expect(result.bytes.sublist(0, 4), equals([0x4F, 0x48, 0x42, 0x4B]));

    // Restore into a fresh DB with a fresh (empty) keychain, by phrase.
    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db2.close);
    var refreshed = false;
    final dst = makeContainer(
      database: db2,
      store: InMemorySecureKeyStore(),
      onAfterRestore: (_) => refreshed = true,
    );
    final outcome = await dst
        .read(backupControllerProvider.notifier)
        .restoreWithPhrase(result.bytes, _validPhrase);

    expect(outcome, RestoreOutcome.success);
    expect(refreshed, isTrue, reason: 'onAfterRestore must fire');

    final babies = await db2.select(db2.babies).get();
    expect(babies, hasLength(1));
    expect(babies.first.name, equals('Alice'));
  });

  test('a non-OHBK blob restores as corruptFile', () async {
    final c = makeContainer(database: db, store: InMemorySecureKeyStore());
    final outcome = await c
        .read(backupControllerProvider.notifier)
        .restoreWithPhrase(Uint8List.fromList(List.filled(64, 0)), _validPhrase);
    expect(outcome, RestoreOutcome.corruptFile);
  });
}
