/// CI-only stub of the encrypted-backup auth module.
///
/// This is NOT the real, audited crypto library — it is a faithful
/// reproduction of the public API surface and the documented OHBK wire format,
/// used so CI can compile the app and run the test suite without checking out
/// the private upstream package. See this directory's pubspec for details.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Base type for all errors thrown by the library.
class SanctuaryAuthException implements Exception {
  const SanctuaryAuthException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when decryption fails: a wrong key or tampered ciphertext (the AEAD
/// authentication tag does not verify).
class CryptoException extends SanctuaryAuthException {
  const CryptoException(super.message);
}

/// Thrown when a backup blob is structurally malformed: too short, wrong magic
/// bytes, or an unknown format version / cipher suite.
class BackupFormatException extends SanctuaryAuthException {
  const BackupFormatException(super.message);
}

/// Thrown by [AuthNotifier.confirmSeedAcknowledged] when the re-entered phrase
/// does not match the stored one.
class SeedPhraseMismatchException extends SanctuaryAuthException {
  const SeedPhraseMismatchException(super.message);
}

// ---------------------------------------------------------------------------
// Envelope cipher (ChaCha20-Poly1305)
// ---------------------------------------------------------------------------

/// Authenticated encryption wrapper around ChaCha20-Poly1305.
class EnvelopeCipher {
  EnvelopeCipher();

  final Cipher _algorithm = Chacha20.poly1305Aead();

  Future<SecretBox> encrypt(List<int> plaintext, List<int> key) {
    return _algorithm.encrypt(plaintext, secretKey: SecretKey(key));
  }

  /// Throws [SecretBoxAuthenticationError] on a wrong key or tampered data.
  Future<List<int>> decrypt(SecretBox box, List<int> key) {
    return _algorithm.decrypt(box, secretKey: SecretKey(key));
  }
}

// ---------------------------------------------------------------------------
// Ghost-tier backup blob (OHBK wire format)
// ---------------------------------------------------------------------------

/// Encodes/decodes the OHBK backup blob:
///
/// ```
/// [ 0..3 ] magic   "OHBK"
/// [ 4    ] version
/// [ 5    ] cipher suite
/// [ 6..17] nonce    (12 bytes)
/// [18..33] MAC      (16 bytes)
/// [34..  ] ciphertext
/// ```
class GhostBackup {
  GhostBackup._();

  static const List<int> _magic = [0x4F, 0x48, 0x42, 0x4B]; // "OHBK"
  static const int _version = 1;
  static const int _suite = 1; // ChaCha20-Poly1305
  static const int _headerLength = 34; // 4 + 1 + 1 + 12 + 16

  static Future<Uint8List> export(
    Uint8List plaintext,
    Uint8List key,
    EnvelopeCipher cipher,
  ) async {
    final box = await cipher.encrypt(plaintext, key);
    final builder = BytesBuilder()
      ..add(_magic)
      ..addByte(_version)
      ..addByte(_suite)
      ..add(box.nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    return builder.toBytes();
  }

  static Future<Uint8List> import(
    Uint8List blob,
    Uint8List key,
    EnvelopeCipher cipher,
  ) async {
    if (blob.length < _headerLength) {
      throw const BackupFormatException('backup blob is too short');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (blob[i] != _magic[i]) {
        throw const BackupFormatException('not an OHBK backup');
      }
    }
    if (blob[4] != _version) {
      throw BackupFormatException('unsupported backup version ${blob[4]}');
    }
    if (blob[5] != _suite) {
      throw BackupFormatException('unsupported cipher suite ${blob[5]}');
    }

    final nonce = blob.sublist(6, 18);
    final mac = blob.sublist(18, 34);
    final cipherText = blob.sublist(34);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));

    try {
      final clear = await cipher.decrypt(box, key);
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const CryptoException('backup authentication failed');
    }
  }
}

// ---------------------------------------------------------------------------
// Key derivation
// ---------------------------------------------------------------------------

/// Keys derived from a seed phrase.
class DerivedKeys {
  const DerivedKeys({required this.masterEncryptionKey});
  final Uint8List masterEncryptionKey;
}

abstract class CryptoService {
  Future<DerivedKeys> deriveKeysFromPhrase(String phrase);
}

class DefaultCryptoService implements CryptoService {
  const DefaultCryptoService();

  static const String _salt = 'sanctuary-auth-core/ghost/v1';

  @override
  Future<DerivedKeys> deriveKeysFromPhrase(String phrase) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 1000,
      bits: 256,
    );
    final normalized = phrase.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
    final derived = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(normalized)),
      nonce: utf8.encode(_salt),
    );
    final bytes = await derived.extractBytes();
    return DerivedKeys(masterEncryptionKey: Uint8List.fromList(bytes));
  }
}

// ---------------------------------------------------------------------------
// Secure key store
// ---------------------------------------------------------------------------

/// Persists the seed phrase and acknowledgement flag. The real implementation
/// uses the OS keychain; this stub keeps state in memory (CI overrides it with
/// a mock anyway).
abstract class SecureKeyStore {
  Future<String?> readMnemonic();
  Future<bool> readSeedAcknowledged();
  Future<DateTime?> readLastBackupAt();
  Future<void> writeMnemonic(String mnemonic);
  Future<void> writeSeedAcknowledged(bool acknowledged);
  Future<void> writeLastBackupAt(DateTime at);
  Future<void> clear();
}

class InMemorySecureKeyStore implements SecureKeyStore {
  String? _mnemonic;
  bool _acknowledged = false;
  DateTime? _lastBackupAt;

  @override
  Future<String?> readMnemonic() async => _mnemonic;

  @override
  Future<bool> readSeedAcknowledged() async => _acknowledged;

  @override
  Future<DateTime?> readLastBackupAt() async => _lastBackupAt;

  @override
  Future<void> writeMnemonic(String mnemonic) async => _mnemonic = mnemonic;

  @override
  Future<void> writeSeedAcknowledged(bool acknowledged) async =>
      _acknowledged = acknowledged;

  @override
  Future<void> writeLastBackupAt(DateTime at) async => _lastBackupAt = at;

  @override
  Future<void> clear() async {
    _mnemonic = null;
    _acknowledged = false;
    _lastBackupAt = null;
  }
}

// ---------------------------------------------------------------------------
// Auth state + notifier
// ---------------------------------------------------------------------------

enum AuthTier { ghost, named }

class AuthState {
  const AuthState({
    required this.tier,
    this.masterEncryptionKey,
    this.seedAcknowledged = false,
    this.lastBackupAt,
  });

  final AuthTier tier;
  final Uint8List? masterEncryptionKey;
  final bool seedAcknowledged;
  final DateTime? lastBackupAt;

  bool needsBackupReminder() =>
      masterEncryptionKey != null && seedAcknowledged && lastBackupAt == null;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  static const List<String> _words = [
    'abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb',
    'abstract', 'absurd', 'abuse', 'access', 'accident', 'account', 'accuse',
    'achieve', 'acid', 'acoustic', 'acquire', 'across', 'action', 'actor',
    'actress', 'actual', 'adapt',
  ];

  @override
  Future<AuthState> build() async {
    final store = ref.watch(secureKeyStoreProvider);
    final crypto = ref.watch(cryptoServiceProvider);

    final mnemonic = await store.readMnemonic();
    final acknowledged = await store.readSeedAcknowledged();
    final lastBackupAt = await store.readLastBackupAt();

    Uint8List? key;
    if (mnemonic != null) {
      final derived = await crypto.deriveKeysFromPhrase(mnemonic);
      key = derived.masterEncryptionKey;
    }

    return AuthState(
      tier: AuthTier.ghost,
      masterEncryptionKey: key,
      seedAcknowledged: acknowledged,
      lastBackupAt: lastBackupAt,
    );
  }

  Future<String> generateSeedPhrase() async {
    final store = ref.read(secureKeyStoreProvider);
    final phrase = _randomMnemonic();
    await store.writeMnemonic(phrase);
    ref.invalidateSelf();
    await future;
    return phrase;
  }

  Future<void> confirmSeedAcknowledged({required String reEntryPhrase}) async {
    final store = ref.read(secureKeyStoreProvider);
    final stored = await store.readMnemonic();
    if (stored == null || _normalize(reEntryPhrase) != _normalize(stored)) {
      throw const SeedPhraseMismatchException('recovery words do not match');
    }
    await store.writeSeedAcknowledged(true);
    ref.invalidateSelf();
    await future;
  }

  Future<void> recordBackupCompleted() async {
    final store = ref.read(secureKeyStoreProvider);
    await store.writeLastBackupAt(DateTime.now());
    ref.invalidateSelf();
    await future;
  }

  Future<void> resetIdentity() async {
    final store = ref.read(secureKeyStoreProvider);
    await store.clear();
    ref.invalidateSelf();
    await future;
  }

  static String _normalize(String phrase) =>
      phrase.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

  static String _randomMnemonic() {
    final rng = Random.secure();
    return List.generate(12, (_) => _words[rng.nextInt(_words.length)]).join(' ');
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final secureKeyStoreProvider =
    Provider<SecureKeyStore>((_) => InMemorySecureKeyStore());

final cryptoServiceProvider =
    Provider<CryptoService>((_) => const DefaultCryptoService());

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
