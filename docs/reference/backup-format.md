# Reference: encrypted backup file format (OHBK)

Precise specification of the `.ohbk` encrypted-backup blob: its byte layout, the
plaintext payload it protects, the decode/fail-safe rules, and the crypto trust
boundary. Rationale: [ADR-0004](../adr/0004-encrypted-backup-seed-phrase.md).

> This describes *intent and current behavior*. The production crypto
> (`sanctuary_auth_core`) is consumed as a path dependency on a sibling
> repository (`../packages/sanctuary_auth_core`), cloned by CI; the byte
> layout below is that real package's wire format, not a stand-in. The
> in-repo CI stub (`ci/auth_stub/`) this app previously shipped has been
> removed.

## Wire format

A backup file is a single binary blob with a fixed **34-byte header** followed by
the AEAD ciphertext:

```
Offset  Len  Field         Value / notes
------  ---  ------------  ----------------------------------------------
0       4    magic         ASCII "OHBK"  = 0x4F 0x48 0x42 0x4B
4       1    version       0x01
5       1    cipher suite  0x01  = ChaCha20-Poly1305
6       12   nonce         AEAD nonce (per-encryption)
18      16   MAC           Poly1305 authentication tag
34      …    ciphertext    AEAD-encrypted payload (see below)
```

Only these 34 header bytes are cleartext. Everything about the contents — even the
record counts and table shapes — is inside the ciphertext. Without the key, the
blob reveals only "this is an OHBK v1 ChaCha20-Poly1305 file."

## Cryptography

- **AEAD:** ChaCha20-Poly1305. Encryption produces `(nonce, ciphertext, MAC)`; the
  MAC authenticates the ciphertext so tampering (or a wrong key) fails on decrypt.
- **Key derivation:** the 256-bit key is derived from the parent's **12-word
  recovery seed phrase** by `sanctuary_auth_core` (PBKDF2-HMAC-SHA512/2048
  over the BIP39-normalized phrase, then HKDF-SHA256; Lullaby keeps
  `appDomain=null`, the legacy household-wide derivation). This KDF differs
  from the retired CI stub's (PBKDF2-HMAC-SHA256/1000, key used directly) —
  see
  [limitations.md](../limitations.md#known-incompatibility-pre-rewire-stub-era-backups)
  for why a pre-rewire export can't be restored under it. The phrase is
  normalized (trim, lowercase, collapse whitespace) before derivation so
  re-entry is forgiving of spacing/case.
- **Keystore:** the seed phrase / key material is held in the OS keychain by
  `sanctuary_auth_core`.

## Plaintext payload (before encryption)

The payload is UTF-8 JSON produced by `BackupSerializer.dumpAll`:

```json
{
  "schemaVersion": 4,
  "exportedAt": "2026-07-03T12:34:56.000Z",
  "tables": {
    "babies":         [ { …row… }, … ],
    "feedingLogs":    [ … ],
    "sleepLogs":      [ … ],
    "diaperLogs":     [ … ],
    "growthRecords":  [ … ],
    "medicineLogs":   [ … ],
    "vaccineRecords": [ … ]
  }
}
```

- Rows are Drift's row JSON; `DateTime` values are encoded as **Unix milliseconds
  (integer)** (the serializer also tolerates ISO-8601 strings on restore).
- `schemaVersion` is the database schema version at export time (currently 4).

## Decode & fail-safe rules

Import/restore rejects anything it cannot fully trust — it never partially
applies. In order:

| Condition | Result |
|---|---|
| blob shorter than 34 bytes | `BackupFormatException` ("too short") |
| bytes 0–3 ≠ `OHBK` | `BackupFormatException` ("not an OHBK backup") |
| version byte ≠ `0x01` | `BackupFormatException` (unsupported version) |
| cipher-suite byte ≠ `0x01` | `BackupFormatException` (unsupported suite) |
| AEAD authentication fails (wrong key or tampered blob) | `CryptoException` |
| payload missing `schemaVersion` or `tables` | `FormatException` |
| payload `schemaVersion` **newer** than the app | `BackupSchemaException` (refuse) |

On success, restore is **destructive and transactional**: within one
transaction it deletes all existing rows (child tables first, to respect foreign
keys) and inserts the backup's rows (babies first). A failure rolls the whole
thing back — you never end up with a half-restored medical record.

## Versioning

The `version` and `cipher suite` header bytes exist so the format can evolve
(a new suite, a new layout) while old readers **refuse** what they don't
understand rather than mis-parse it. Refusing a *newer* `schemaVersion` on restore
(rather than dropping unknown fields) is the same fail-safe posture at the data
layer: update the app, then restore.
