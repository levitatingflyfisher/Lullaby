import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../home_widget/presentation/controllers/home_widget_controller.dart';
import '../../../tracking/presentation/controllers/timer_controller.dart';
import '../../data/backup_serializer.dart';
import '../../domain/backup_repository.dart';

/// The distinguishable outcomes of a restore attempt, so the UI can show a
/// legible, specific message instead of one catch-all string (M1).
enum RestoreOutcome { success, noKey, wrongPhrase, corruptFile, tooNewBackup, failed }

/// Manages backup operations: seed phrase generation, export, and restore.
class BackupController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Generates a new 12-word seed phrase and returns it for display.
  /// The phrase is persisted in the OS keychain by sanctuary_auth_core.
  Future<String?> generateSeedPhrase() async {
    state = const AsyncLoading();
    try {
      final phrase =
          await ref.read(authNotifierProvider.notifier).generateSeedPhrase();
      state = const AsyncData(null);
      return phrase;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Records that the user has written down their seed phrase.
  ///
  /// [reEntryPhrase] must match the phrase previously returned by
  /// [generateSeedPhrase]; the library uses this to convert a UX assertion
  /// ("I clicked 'got it'") into a cryptographic check ("I can reproduce the
  /// phrase"). Returns `true` on success, `false` on mismatch.
  Future<bool> confirmSeedAcknowledged(String reEntryPhrase) async {
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .confirmSeedAcknowledged(reEntryPhrase: reEntryPhrase);
      return true;
    } on SeedPhraseMismatchException {
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Exports an encrypted backup blob and returns it with a suggested filename.
  /// Returns null on failure.
  Future<({Uint8List bytes, String filename})?> exportBackup() async {
    state = const AsyncLoading();
    try {
      final authState = await ref.read(authNotifierProvider.future);
      final key = authState.masterEncryptionKey;
      if (key == null) {
        state = AsyncError(
          StateError('No encryption key — set up a seed phrase first.'),
          StackTrace.current,
        );
        return null;
      }

      final repo = ref.read(backupRepositoryProvider);
      final blob = await repo.export(key);

      await ref.read(authNotifierProvider.notifier).recordBackupCompleted();

      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      state = const AsyncData(null);
      return (bytes: blob, filename: 'lullaby-backup-$date.ohbk');
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Decrypts and restores data from an OHBK blob using the user's current
  /// master key.
  Future<RestoreOutcome> restoreFromBlob(Uint8List blob) async {
    final authState = await ref.read(authNotifierProvider.future);
    final key = authState.masterEncryptionKey;
    if (key == null) return RestoreOutcome.noKey;
    return _runRestore(
        () => ref.read(backupRepositoryProvider).restore(blob, key));
  }

  /// Restores from a blob using a manually entered seed phrase — used on fresh
  /// installs, or when this device's key doesn't match the backup (M2).
  Future<RestoreOutcome> restoreWithPhrase(Uint8List blob, String phrase) async {
    // Derive inside the guarded action: an invalid phrase makes
    // deriveKeysFromPhrase throw (CryptoException), which must map to
    // wrongPhrase rather than escape as an unhandled error (and no snackbar).
    return _runRestore(() async {
      final keys =
          await ref.read(cryptoServiceProvider).deriveKeysFromPhrase(phrase);
      await ref
          .read(backupRepositoryProvider)
          .restore(blob, keys.masterEncryptionKey);
    });
  }

  Future<RestoreOutcome> _runRestore(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      _refreshAfterRestore();
      state = const AsyncData(null);
      return RestoreOutcome.success;
    } on CryptoException catch (e, st) {
      state = AsyncError(e, st);
      return RestoreOutcome.wrongPhrase;
    } on BackupSchemaException catch (e, st) {
      state = AsyncError(e, st);
      return RestoreOutcome.tooNewBackup;
    } on BackupFormatException catch (e, st) {
      state = AsyncError(e, st);
      return RestoreOutcome.corruptFile;
    } on FormatException catch (e, st) {
      state = AsyncError(e, st);
      return RestoreOutcome.corruptFile;
    } catch (e, st) {
      state = AsyncError(e, st);
      return RestoreOutcome.failed;
    }
  }

  /// After a destructive restore the Drift watch streams self-refresh, but
  /// in-memory timers and the home widget can still reference wiped rows (M4).
  void _refreshAfterRestore() {
    ref.invalidate(activeTimersProvider);
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
  }

  /// Wipes all key material. Drift data is NOT affected.
  Future<void> resetIdentity() async {
    state = const AsyncLoading();
    try {
      await ref.read(authNotifierProvider.notifier).resetIdentity();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final backupControllerProvider =
    NotifierProvider<BackupController, AsyncValue<void>>(
  BackupController.new,
);
