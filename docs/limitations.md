# Limitations

Read this before adopting Lullaby or building on it. An honest list of what it
does **not** do (as of v1.0.0). For the built-vs-aspirational split see
[VISION.md § Honest scorecard](../VISION.md#honest-scorecard--built-vs-aspirational).

## It is not a medical device

Lullaby is a **record-keeping tool**, not a diagnostic one. The WHO percentile
curves are reference standards for orientation, not an assessment. Nothing in the
app is medical advice. Anything concerning goes to a paediatrician — the doctor
summary exists to *help that conversation*, not replace it.

## No multi-device sync

There is no cloud and no live sync between devices. Two parents sharing a baby
today means either **one shared device** or **carrying an encrypted backup file**
between phones and restoring it (a destructive, full replace — not a merge).
Server-free sync with real merge semantics is an open design problem, not a
shipped feature (see [VISION.md](../VISION.md) Horizons).

## No account recovery

By design there is no account, so there is no "reset password" email. If a parent
sets up an encrypted backup and **loses the seed phrase, the backup is
unrecoverable.** If the phone is lost with no backup, the data is gone. This is
the deliberate cost of holding your own keys ([ADR-0001](adr/0001-local-first-no-account.md),
[ADR-0004](adr/0004-encrypted-backup-seed-phrase.md)).

## Known incompatibility: pre-rewire (stub-era) backups

Lullaby's encrypted-backup feature originally ran on an in-repo CI stub for
its crypto, before this codebase was re-wired onto the real, audited
`sanctuary_auth_core` package. If you ever exported an `.ohbk` file from a
build that predates the re-wire, **that file cannot be restored** by the
current app. The stub's key derivation (PBKDF2-HMAC-SHA256/1000 iterations)
is a different algorithm from the real core's (PBKDF2-HMAC-SHA512/2048 →
HKDF), so the same recovery phrase now derives a different key — the OHBK
wire format itself didn't change, but the key needed to open the ciphertext
isn't recoverable from the phrase alone.

In practice we have no known affected user: the stub-era build kept its keystore
in-memory only, so a seed phrase never survived an app restart, meaning there
was no persistent stub-era identity or backup corpus to begin with — any such
export was already unrestorable under the stub itself by the time the app was
closed. Restoring on the real core is the first release where a backup you
make today will still work tomorrow. See
`test/unit/features/sanctuary_backup/stub_compat_gate_test.dart` for the
specific proof (wire format compatible, key derivation is not).

## The production crypto is now vendored via sibling packages

The encrypted-backup module (`sanctuary_auth_core`) and its Flutter UI layer
(`sanctuary_backup_ui`) are consumed as path dependencies on sibling
repositories (`../packages/sanctuary_auth_core`,
`../packages/sanctuary_backup_ui`), not a private out-of-repo package and not
an in-repo stub. The in-repo CI stub (`ci/auth_stub/`) that this app
previously shipped in production has been removed; CI now clones the real
sibling packages instead.

## The local database file is not itself encrypted

Data at rest lives in a plain SQLite file in the app's private storage.
Confidentiality of that file rests on **device full-disk encryption and the OS app
sandbox**, not on app-level encryption — only the *backup* file is encrypted.
There is also **no in-app PIN or biometric lock**: anyone holding the unlocked
device can open the app. See [privacy-model.md](privacy-model.md).

## Feature gaps

- **No reminders or notifications** — the app does not schedule feed/medicine
  reminders.
- **A "named"/synced tier** exists in the auth enum but is not implemented; only
  the ghost tier runs.
- **Screenshots** are still "coming soon" in the README.

## Not yet published

The Android `applicationId` is still `com.example.lullaby`. Publishing to an app
store requires a real reverse-domain identifier and a release signing key
(release CI is intentionally omitted until then — see `.github/workflows/ci.yml`).

## CI coverage is partial

CI runs `flutter analyze` and `flutter test` on **Linux only**. Android, iOS,
Linux desktop, and web are supported build targets but are **not** exercised by
CI, so a platform-specific regression could land without CI catching it.
