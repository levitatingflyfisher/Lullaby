# Privacy model

Lullaby records an infant's protected health information. This document states
**exactly what happens to that data**, what leaves the device and when, what the
threat model does and does not cover, and — importantly — how you can *verify* the
claims rather than take them on faith.

## The one-line promise

**Nothing leaves your device unless you deliberately send it.** There is no
account, no server, no analytics, no ads. In normal use the app makes zero network
calls.

## Where data lives

All records live in a single on-device **SQLite** database (`lullaby.sqlite` in
the app's private documents directory; on web, a `sqlite3.wasm` database in
browser storage). Baby avatar photos are stored on-device via the OS image
picker. That is the whole footprint.

> **Honest caveat:** the local database file is **not itself encrypted.** Its
> confidentiality rests on **device full-disk encryption + the OS app sandbox**.
> There is also **no in-app PIN or biometric lock** — anyone with the unlocked
> phone can open Lullaby and read everything. Only the *backup file* is encrypted
> (below). If you share a device, everyone with it shares the record.

## What can leave the device — the three explicit exits

Data leaves only by an action the parent takes on purpose:

| Exit | What it contains | Protection | Where it goes |
|---|---|---|---|
| **CSV / PDF export** | The chosen records (e.g. a doctor summary) | **Plaintext.** CSV cells are formula-injection-neutralized ([safety rules](reference/csv-export-safety.md)) | Wherever the parent sends it via the OS share sheet |
| **Encrypted backup (`.ohbk`)** | All records, serialized to JSON | **Encrypted** with ChaCha20-Poly1305 under a key derived from the parent's seed phrase ([format](reference/backup-format.md)) | A file the parent saves and carries |
| **Home-screen widget** | Baby name + "last feed/sleep/diaper" times + active timer | None (it's a glanceable widget) | Stays **on-device**, but rendered on the home/lock screen by the OS launcher |

Two notes:
- A **plaintext export is only as private as where you send it.** Emailing a PDF
  puts it on mail servers. That is the parent's choice, made explicitly.
- The **home widget** never transmits anything, but it does surface the baby's
  name and recent activity on the home screen, which is visible to anyone looking
  at the phone.

## The backup crypto trust boundary

The encryption itself lives in `sanctuary_auth_core`, consumed as a path
dependency on a sibling repository (`../packages/sanctuary_auth_core`), plus
its Flutter UI layer `sanctuary_backup_ui` (`../packages/sanctuary_backup_ui`).
CI clones both sibling packages so a fresh checkout builds and tests without
any credentials. Lullaby previously vendored an in-repo **CI stub**
(`ci/auth_stub/`) with placeholder KDF parameters and an in-memory keystore;
that stub has been removed — the app now runs the real, audited crypto in
every build, not just release builds. See a pre-rewire `.ohbk` export's
non-recoverability under the real KDF in
[limitations.md](limitations.md#known-incompatibility-pre-rewire-stub-era-backups)
and [ADR-0004](adr/0004-encrypted-backup-seed-phrase.md).

## Threat model

**In scope (what the design protects against):**
- **Passive data collection / profiling** — there is nothing to collect; no
  network egress, no identifiers, no telemetry.
- **A leaked backup file** — it is AEAD-encrypted; without the seed phrase it is
  opaque, and tampering fails the authentication tag on restore.
- **A server breach** — there is no server.

**Out of scope (what it does *not* protect against):**
- **A compromised or malware-infected device** — malware with app-data access can
  read the unencrypted local DB. Nothing app-level stops that.
- **Physical access to the unlocked phone** — no in-app lock; the record is
  readable, and the home widget shows recent activity.
- **A lost seed phrase** — the encrypted backup becomes unrecoverable (by design;
  no escrow).
- **What you do with a plaintext export** — once shared, its privacy is the
  recipient's and the transport's.

## How to verify these claims

Don't trust the prose — check it:

```bash
# 1. No network / analytics / BaaS dependency in the build:
grep -niE 'firebase|supabase|analytics|sentry|crashlytics|dio|http|amplitude|mixpanel' pubspec.yaml

# 2. No HTTP client or tracking call anywhere in the app source:
grep -rniE 'http(s)?://|HttpClient|package:http|firebase|analytics' lib/

# 3. Android permissions — confirm no unexpected network/location grants:
cat android/app/src/main/AndroidManifest.xml
```

The first two commands should return nothing app-relevant; the manifest should
not request tracking, location, or background-network permissions. Privacy that
you can grep for is the point.
