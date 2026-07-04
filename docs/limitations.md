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

## The production crypto is not in this repo

The encrypted-backup module (`sanctuary_auth_core`) is a private, out-of-repo
package. This repository ships only a **CI stub** (`ci/auth_stub/`) that
reproduces the public API and the OHBK wire format so the app compiles and the
tests run. **The stub is not the audited library and must not be shipped in a
release build.** Its key-derivation parameters and in-memory keystore are
placeholders, not the security spec.

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
