# Privacy model

Lullaby records an infant's protected health information. This document states
**exactly what happens to that data**, what leaves the device and when, what the
threat model does and does not cover, and — importantly — how you can *verify* the
claims rather than take them on faith.

## The one-line promise

**Nothing leaves your device unless you deliberately send it.** There is no
account, no server of record, no analytics, no ads. Until a parent turns on sync,
the app makes zero network calls; after that it talks only to the relay the
household chose and, while a parent shows or types a same-Wi-Fi code, to the
other phone on the local network, and sends either only sealed changes.

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
| **Sync** (opt-in, [ADR-0007](adr/0007-household-sync.md)) | Every record change and handoff note, as signed ops | **Sealed** (XChaCha20-Poly1305) under a key derived from the household's 12 words; signed by this phone's own device key | The household relay the parent typed in, and on to the household's other phones; or, with a same-Wi-Fi code, straight to the other phone (plain HTTP on the local network, every message MAC'd under a key only a holder of the words can compute; hearthSync ADR 0014) |
| **Home-screen widget** | Baby name + "last feed/sleep/diaper" times + active timer | None (it's a glanceable widget) | Stays **on-device**, but rendered on the home/lock screen by the OS launcher |

Two notes:
- A **plaintext export is only as private as where you send it.** Emailing a PDF
  puts it on mail servers. That is the parent's choice, made explicitly.
- The **home widget** never transmits anything, but it does surface the baby's
  name and recent activity on the home screen, which is visible to anyone looking
  at the phone.

## What the relay sees, and what it cannot

With sync on, the relay stores sealed envelopes and passes them on. It cannot
open them: the key comes from the 12 words, which never leave the phones. It
does see: the household's channel id (derived from the words, not secret), each
phone's public device key and **its name in plain text** (the name typed when
sync was turned on, so "Phone 2" reveals less than a person's name), how many
changes and how big, and when. Photos never sync (`photo_path` is a file on one phone).
"Forget this phone" stops future updates; no design can recall what another
phone already holds. Every phone stores the words (fleet sync decision 2), so
the phrase gate on Forget protects against a child's tap, not against a holder
of the words.

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
- **A server breach** — there is no server of record. A breached relay yields
  sealed envelopes and metadata (sizes, timing, device keys), no content.

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
# 1. No analytics / BaaS dependency in the build (hearth_sync is the sync kernel):
grep -niE 'firebase|supabase|analytics|sentry|crashlytics|dio|amplitude|mixpanel' pubspec.yaml

# 2. No HTTP client or tracking call in the app's own source; the only network
#    code is hearth_sync's relay client, reached through HouseholdSync:
grep -rniE 'HttpClient|package:http|firebase|analytics' lib/

# 3. Android permissions: INTERNET (for sync) and nothing else:
cat android/app/src/main/AndroidManifest.xml

# 4. With sync off, no kernel, no relay client and no Wi-Fi listener are ever created:
flutter test test/unit/features/sync/household_sync_off_test.dart
```

The first two should return nothing app-relevant; the manifest should ask for
`INTERNET` only (conformance C4 pins that set). Privacy that you can grep for
is the point.
