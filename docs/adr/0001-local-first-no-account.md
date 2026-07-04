# ADR-0001: Local-first, on-device only, no account or BaaS

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision load-bearing since v1.0.0)

## Context

Lullaby records an infant's protected health information — feeds, sleep,
medicines, vaccines, growth. The dominant baby-tracker apps store this in the
cloud behind an account, which makes the family's most intimate data the
vendor's asset, subject to breaches, policy changes, and monetization. The whole
reason to build a *free, open* alternative is to not do that.

The parents who most need the app — sleep-deprived, one-handed, often offline in
a nursery at 3 a.m. — are also the ones for whom a login screen or a "no
connection" error is the most hostile.

## Decision

Store everything **on the device** in a local SQLite database (via Drift). The
app requires **no account** and makes **no network calls** in normal operation:
no sync server, no analytics, no crash telemetry, no ad SDK. Offline is the whole
design, not a degraded mode. Any Backend-as-a-Service (Firebase, Supabase,
Auth0, etc.) is excluded by construction.

Data may leave the device only by a parent's **explicit, user-initiated** action:
an export (CSV/PDF via the OS share sheet) or an encrypted backup file
([ADR-0004](0004-encrypted-backup-seed-phrase.md)).

## Consequences

- **Buys:** the privacy promise is architectural and *checkable* — `pubspec.yaml`
  has no network/analytics dependency and `lib/` has no HTTP client. Instant
  startup, full offline function, no server to run or breach.
- **Costs:** no built-in multi-device sync and no cloud safety net. If a parent
  loses the phone without a backup, the data is gone. Cross-device sharing is an
  open design problem (see [VISION.md](../../VISION.md) Horizons).
- **Forecloses:** any feature that assumes a server of record, a user directory,
  or server-side analytics. Those would require a new ADR and would break the
  core promise.

## Alternatives considered

- **Cloud-first with an account:** rejected — it is precisely the model this app
  exists to replace.
- **Optional cloud sync via a BaaS:** rejected for core — a BaaS sees plaintext
  and creates an account/identity. If sync ever ships it must be
  encrypted-blob-through-a-dumb-relay, never a BaaS.
