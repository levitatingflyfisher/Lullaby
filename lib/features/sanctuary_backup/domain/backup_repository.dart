import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../data/backup_serializer.dart';

/// Orchestrates [BackupSerializer] and [GhostBackup] to produce/consume
/// encrypted `.ohbk` backup blobs.
class BackupRepository {
  final BackupSerializer _serializer;
  final EnvelopeCipher _cipher;

  const BackupRepository(this._serializer, this._cipher);

  /// Serializes all Lullaby data, encrypts it under [key], and returns the
  /// OHBK blob bytes ready to be saved to a file.
  Future<Uint8List> export(Uint8List key) async {
    final plaintext = await _serializer.dumpAll();
    return GhostBackup.export(plaintext, key, _cipher);
  }

  /// Decrypts an OHBK [blob] with [key] and restores all data into the
  /// database, replacing any existing data.
  ///
  /// Throws [BackupFormatException] for malformed blobs.
  /// Throws [CryptoException] for wrong key or tampered data.
  /// Throws [BackupSchemaException] for future schema versions.
  Future<void> restore(Uint8List blob, Uint8List key) async {
    final plaintext = await GhostBackup.import(blob, key, _cipher);
    await _serializer.restoreAll(plaintext);
  }
}

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final cipher = ref.watch(envelopeCipherProvider);
  return BackupRepository(BackupSerializer(db), cipher);
});
