# ADR-0004: Encrypted backup via a seed phrase; crypto lives out-of-repo

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision load-bearing since v1.0.0)
- **Update (2026-07-12):** the in-repo CI stub (`ci/auth_stub/`) described
  below has been removed. The app now consumes the real `sanctuary_auth_core`
  and `sanctuary_backup_ui` packages as sibling-repo path dependencies in
  every build, not just release builds — see
  [docs/privacy-model.md](../privacy-model.md) and
  [docs/limitations.md](../limitations.md#known-incompatibility-pre-rewire-stub-era-backups)
  for current behavior. The decision record below is left as originally
  written.

## Context

Local-first data ([ADR-0001](0001-local-first-no-account.md)) has one real
downside: lose the phone, lose the record. Parents need a way to back up and move
their data — but a backup must not reintroduce the very thing we rejected (an
account, a server that sees plaintext). So the backup has to be **encrypted on
the device, under a key only the parent holds**, and portable as a plain file.

Auth/crypto is also security-sensitive code that should be written and audited
once and shared across OpenHearth apps, not re-implemented per app.

## Decision

Back up by **serializing all data to JSON, encrypting it under a key derived from
a user-held recovery seed phrase, and writing a single `.ohbk` file** the parent
saves and carries. There is no server and no account — the seed phrase is a
recovery key, not a login.

- The **key** is derived from a 12-word seed phrase (PBKDF2). The user proves they
  wrote the phrase down by re-entering it — turning a UX assertion into a
  cryptographic check.
- The payload is encrypted with **ChaCha20-Poly1305** (AEAD) and framed in the
  **OHBK wire format** (see [reference/backup-format.md](../reference/backup-format.md)).
- **Restore is destructive and transactional**: wipe-then-insert in one
  transaction; a backup whose schema version is newer than the app is rejected.
- The crypto lives in a **separate, out-of-repo package** (`sanctuary_auth_core`),
  consumed via a path dependency. This repo vendors only a **CI stub** at
  `ci/auth_stub/` so the app compiles and the suite runs without the private
  package; the stub reproduces the public API and the OHBK format but its KDF
  parameters and in-memory keystore are **not** the production security spec.

## Consequences

- **Buys:** durable, portable backups with zero server and zero plaintext egress;
  a shared, auditable crypto module; a testable app that doesn't depend on
  checking out a private package.
- **Costs:** the seed phrase is unrecoverable if lost (no reset email — by
  design). Release builds **must** swap the stub for the audited package; shipping
  the stub in production would be a security defect. The split adds a build/wiring
  step and a trust boundary to document.
- **Forecloses:** server-side key escrow or account-based recovery. Recovery is
  the parent's responsibility, mediated only by the seed phrase.

## Alternatives considered

- **Plaintext export as the only backup:** rejected — a plaintext medical dump is
  a liability if it leaks; encryption at rest is the point.
- **In-repo crypto:** rejected — security code belongs in one audited, shared
  place; duplicating it per app multiplies the audit surface.
- **Account-based cloud backup:** rejected — reintroduces the account and the
  plaintext-seeing server this app exists to avoid ([ADR-0001](0001-local-first-no-account.md)).
