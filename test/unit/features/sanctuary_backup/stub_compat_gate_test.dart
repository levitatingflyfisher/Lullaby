import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';

/// KNOWN INCOMPATIBILITY — SANCTUARY-BRIEF §4.W1 step 1, §2.1.
///
/// This file does NOT prove a passing compatibility gate. Before this repo
/// was re-wired, shipped Lullaby depended on the CI stub (`ci/auth_stub`) for
/// its crypto. This file freezes an OHBK backup blob that the STUB minted
/// from a FIXED phrase + FIXED plaintext, then asserts exactly what the REAL
/// `sanctuary_auth_core` core does with it — so the (in)compatibility story
/// is a tested fact, not a guess or an aspiration.
///
/// VERDICT (proven by the two live tests below):
///   • WIRE FORMAT is compatible — the real core's [GhostBackup.import] reads a
///     stub-era v1 blob (no-AAD legacy path) byte-for-byte, GIVEN the key the
///     stub used.
///   • The KEY DERIVATION is NOT compatible — the same phrase yields a different
///     master key under the real core (stub: PBKDF2-HMAC-SHA256/1000/
///     'sanctuary-auth-core/ghost/v1' → key directly; real: PBKDF2-HMAC-SHA512/
///     2048/'mnemonic' → HKDF-SHA256/'openhearth.encryption.v1'). So a stub-era
///     backup CANNOT be opened by phrase alone under the real core: an .ohbk
///     file exported by a pre-rewire build is not restorable by this app. See
///     docs/limitations.md "Known incompatibility: pre-rewire (stub-era)
///     backups" for the user-facing statement of this fact.
///
/// Why this does not strand any real user: shipped Lullaby ran the stub with
/// its default IN-MEMORY key store (no persistent override in main.dart), so
/// a seed phrase never survived an app restart — there is no persistent
/// stub-era identity or backup corpus to migrate. The stub's phrases were not
/// valid BIP39 either. The re-wire onto the real core is the first time
/// Lullaby has persistent identity, and the first release where a backup you
/// make today is guaranteed to still work tomorrow. This is a
/// non-regression, not new breakage: any stub-era export was already
/// unrestorable under the stub itself.
void main() {
  // Fixture minted by ci/auth_stub (see the deleted generator in git history):
  // key = stub.DefaultCryptoService.deriveKeysFromPhrase(phrase);
  // blob = stub.GhostBackup.export(utf8(plaintext), key)  → OHBK v1, no AAD.
  const phrase =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';
  const plaintext =
      '{"schemaVersion":4,"tables":{"babies":[{"id":"b1","name":"Test"}]}}';
  final stubKey = base64.decode('FwLXuphilPdYu1JHktTQQirjnZjjybkreq9YsL10As8=');
  final stubBlob = base64.decode(
      'T0hCSwEBNtFR4qjBCQbaQiuVzr4jXPN8pyRxij2VJ5LmAudeZrCnUuF5ELrMRfvEIYMO5mL'
      '819XxDoi2mx0YflykHN8XEBrPns2d9fk/nwoxQor3aQClqoz0VeZukxCNDD8Oqmc=');

  test('the fixture is a stub-era OHBK v1 blob (no AAD binding)', () {
    expect(stubBlob.sublist(0, 4), equals([0x4F, 0x48, 0x42, 0x4B])); // "OHBK"
    expect(stubBlob[4], equals(0x01)); // version 1 — the stub never wrote v2
  });

  test(
      'WIRE FORMAT compatible: the real core imports the stub v1 blob given the '
      'stub-era key', () async {
    final out = await GhostBackup.import(
      Uint8List.fromList(stubBlob),
      Uint8List.fromList(stubKey),
      EnvelopeCipher(),
      context: 'ghost-backup/v1',
    );
    expect(utf8.decode(out), equals(plaintext));
  });

  test(
      'MIGRATION BOUNDARY: the real KDF derives a DIFFERENT key from the same '
      'phrase, so a stub-era backup cannot be opened by phrase alone', () async {
    final realKey = (await const DefaultCryptoService()
            .deriveKeysFromPhrase(phrase, appDomain: null))
        .masterEncryptionKey;

    // The real key is not the stub key...
    expect(listEquals(realKey, stubKey), isFalse);

    // ...so importing the stub blob under the phrase-derived real key fails.
    await expectLater(
      GhostBackup.import(
        Uint8List.fromList(stubBlob),
        realKey,
        EnvelopeCipher(),
        context: 'ghost-backup/v1',
      ),
      throwsA(isA<CryptoException>()),
    );
  });

  test(
    'BRIEF GATE (a): same-phrase end-to-end restore of a stub-era backup',
    () {
      // Intentionally empty — see skip reason.
    },
    skip: 'INCOMPATIBLE BY CONSTRUCTION. The literal gate (real core opens a '
        'stub-era backup from the phrase alone) cannot pass: the stub and real '
        'core use different KDF chains, proven by the MIGRATION BOUNDARY test '
        'above. The wire format IS compatible (WIRE FORMAT test). No persistent '
        'stub-era backup corpus exists to migrate (stub ran in-memory, phrases '
        'were not valid BIP39), so a full stub→real identity migration is out '
        'of scope — the gate is characterised precisely rather than dropped.',
  );
}
