import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/providers/auth_providers.dart';
import 'package:lullaby/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:lullaby/features/sanctuary_backup/domain/backup_repository.dart';
import 'package:lullaby/features/sanctuary_backup/presentation/controllers/backup_controller.dart';
import 'package:lullaby/services/database/database.dart';

import '../../../test_setup.dart';

/// CryptoService that yields a fixed key, or throws on derive to simulate an
/// invalid recovery phrase.
class _FakeCrypto implements CryptoService {
  _FakeCrypto({this.throwOnDerive});
  final Object? throwOnDerive;

  @override
  String generateMnemonic() =>
      'test test test test test test test test test test test junk';

  @override
  Future<DerivedKeys> deriveKeysFromPhrase(String phrase) async {
    final err = throwOnDerive;
    if (err != null) throw err;
    return DerivedKeys(
      masterEncryptionKey: Uint8List(32),
      syncKey: Uint8List(32),
      authKey: Uint8List(32),
      recoveryKey: Uint8List(32),
      syncChannelId: Uint8List(32),
    );
  }
}

/// BackupRepository whose restore() always throws [error]. The super
/// serializer/cipher are never exercised because restore is overridden.
class _ThrowingBackupRepo extends BackupRepository {
  _ThrowingBackupRepo(super.serializer, super.cipher, this.error);
  final Object error;

  @override
  Future<void> restore(Uint8List blob, Uint8List key) async => throw error;
}

void main() {
  ensureSqlite3();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  // A container whose restore() throws [restoreError]; the phrase derivation
  // succeeds unless [deriveError] is supplied.
  ProviderContainer makeContainer({Object? restoreError, Object? deriveError}) {
    final repo = _ThrowingBackupRepo(
        BackupSerializer(db), EnvelopeCipher(), restoreError ?? Exception('x'));
    return ProviderContainer(overrides: [
      cryptoServiceProvider
          .overrideWithValue(_FakeCrypto(throwOnDerive: deriveError)),
      backupRepositoryProvider.overrideWithValue(repo),
    ]);
  }

  final blob = Uint8List.fromList([1, 2, 3]);

  Future<RestoreOutcome> restore(ProviderContainer c) =>
      c.read(backupControllerProvider.notifier).restoreWithPhrase(blob, 'words');

  group('BackupController.restoreWithPhrase error mapping', () {
    test('an invalid phrase (derive throws) maps to wrongPhrase, not a throw',
        () async {
      // Regression guard: deriveKeysFromPhrase must run inside the guarded
      // path, so a bad mnemonic surfaces as a legible outcome rather than an
      // unhandled exception (no snackbar).
      final container =
          makeContainer(deriveError: CryptoException('bad mnemonic'));
      addTearDown(container.dispose);

      expect(await restore(container), RestoreOutcome.wrongPhrase);
    });

    test('a wrong key / tampered blob maps to wrongPhrase', () async {
      final container =
          makeContainer(restoreError: CryptoException('wrong key'));
      addTearDown(container.dispose);

      expect(await restore(container), RestoreOutcome.wrongPhrase);
    });

    test('a malformed blob maps to corruptFile', () async {
      final container =
          makeContainer(restoreError: BackupFormatException('bad magic'));
      addTearDown(container.dispose);

      expect(await restore(container), RestoreOutcome.corruptFile);
    });

    test('a future schema version maps to tooNewBackup', () async {
      final container =
          makeContainer(restoreError: const BackupSchemaException(99, 1));
      addTearDown(container.dispose);

      expect(await restore(container), RestoreOutcome.tooNewBackup);
    });

    test('an unexpected error maps to failed', () async {
      final container = makeContainer(restoreError: StateError('boom'));
      addTearDown(container.dispose);

      expect(await restore(container), RestoreOutcome.failed);
    });
  });
}
