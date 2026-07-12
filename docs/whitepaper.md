# Lullaby — White Paper

*A baby tracker where the child's data never leaves the parents' phone: the calm,
private, no-account alternative to cloud baby-tracking apps.*

**Status:** conceptual/strategic overview. For the design commitments see
[VISION.md](../VISION.md); for the mechanics, [architecture/OVERVIEW.md](architecture/OVERVIEW.md);
for exactly what leaves the device, [privacy-model.md](privacy-model.md). This
document is honest about the line between what is built and what is aspirational —
see §6.

---

## Abstract

A newborn produces one of the most intimate medical records a family will ever
keep: every feed, every hour of sleep, every diaper, every medicine and vaccine,
tracked around the clock. The popular apps that help parents record this stream do
so in the cloud, behind an account, turning a baby's health data into the
vendor's asset — subject to breaches, terms-of-service changes, ad targeting, and
acquisition. Lullaby is the opposite bet: a fully featured tracker whose data
lives **only on the device**, requires **no account**, makes **no network calls**
in normal use, and leaves the phone only when a parent deliberately exports or
backs it up. It shows that "private" and "capable" are not in tension for this
class of app.

## 1. The problem

Tracking an infant is genuinely useful — patterns in feeding and sleep matter,
growth against percentile curves matters, a clean medicine and vaccine history
matters at every appointment. So parents reach for an app. And the app, almost
always, asks them to create an account and syncs their baby's health data to a
server they don't control.

The costs are quiet but real:
- **The data becomes an asset.** Infant health data is valuable and sensitive;
  once it's on someone's server it can be breached, sold, mined for ads, or
  swept up in an acquisition.
- **It assumes connectivity and identity.** A login wall and a spinner are
  hostile to the exact user — exhausted, one-handed, often offline in a dark
  nursery — the app is supposed to serve.
- **It outlives the parent's consent.** The child cannot consent; the account
  terms can change; the export may be a locked-in format or nonexistent.

## 2. The idea

**Keep the data on the device, and make that the whole architecture — not a
setting.**

Lullaby stores everything in an on-device SQLite database. There is no account,
no server of record, no analytics SDK, and no ad SDK anywhere in the build. The
app is fully functional in airplane mode because offline *is* the design. This is
not "privacy mode"; it is the only mode. The result is a promise you can check by
reading `pubspec.yaml` and grepping `lib/` — there is no HTTP client to find.

Data leaves only through two deliberate, parent-initiated exits: a **plaintext
export** (a doctor-summary PDF or a CSV) shared via the OS share sheet, and an
**encrypted backup file** the parent saves and carries. Nothing is transmitted
automatically, ever.

## 3. Why local-first matters *here* specifically

Local-first is an OpenHearth value, but for a baby tracker it is unusually
load-bearing:

- **The data is medical and about a non-consenting person.** The bar for "don't
  put this on someone else's computer" is at its highest.
- **The usage context is offline and one-handed.** 3 a.m., no Wi-Fi, a crying
  baby. An app that needs a network round-trip to log a feed has already failed.
- **The record must be portable and durable.** A parent should be able to hand a
  clean summary to a paediatrician and to move their whole history to a new phone
  — without a vendor in the middle. Hence a **safe** export (CSV cells are
  neutralized against spreadsheet formula injection — see
  [reference/csv-export-safety.md](reference/csv-export-safety.md)) and an
  **encrypted, self-custodied** backup ([reference/backup-format.md](reference/backup-format.md)).

## 4. How it differs from the cloud incumbent

| | Cloud baby trackers | Lullaby |
|---|---|---|
| Account | Required | None — ever |
| Where the data lives | Vendor's servers | Your device |
| Works offline | Partially | Fully (offline is the design) |
| Ads / tracking / analytics | Common | None (architecturally absent) |
| Backup | Vendor-held, plaintext to them | Self-custodied, **encrypted** file |
| Export | Often locked-in or absent | PDF + CSV you own, safe to open |
| Source | Closed | FLOSS (MIT) |
| Business model | Your data / subscription | None — it's a free tool |

The trade Lullaby accepts, honestly: **no built-in multi-device sync and no
account recovery.** Holding your own keys means that if you lose both the phone
and the seed phrase, the data is gone. That is the price of nobody else holding
your child's record, and it is the right price for this data.

## 5. The architecture, in brief

Flutter, Clean Architecture, feature-first. Each feature is `domain` (entities +
an abstract repository), `data` (a Drift-backed implementation), and
`presentation` (screens + Riverpod controllers), with dependencies pointing
inward so the trackers are testable against an in-memory database. One SQLite
schema runs on native platforms and in the browser (WebAssembly SQLite) behind a
single conditional connection. Roughly 450 tests, including golden tests for
layout, gate every change through CI. Full detail:
[architecture/OVERVIEW.md](architecture/OVERVIEW.md) and the
[ADRs](adr/).

## 6. What is built, and what is not

A white paper that overclaims is marketing. Honestly, as of v1.0.0:

**Built, tested, load-bearing:** the complete tracking suite (feeding, sleep,
diaper, growth with WHO curves, medicine, vaccine); dashboard, calendar,
timeline, statistics, and doctor summary; PDF and CSV export with tested
formula-injection safety; on-device Drift/SQLite with enforced foreign keys and
migrations; the encrypted-backup app flow and OHBK wire format. It runs with no
account and no network.

**Aspirational / partial — documents, not fully shipped:** the audited backup
crypto (`sanctuary_auth_core`) is consumed as a sibling-repo path dependency
rather than published on pub.dev, so building from a fresh checkout still
requires cloning the sibling packages; a **"named"/synced tier** exists in
the enum but is unimplemented (only the
account-free ghost tier runs); **multi-device sync** with real merge semantics is
unbuilt (the hard, honest open problem — see [VISION.md](../VISION.md) Horizons);
the app is **not yet published** (`applicationId` is still `com.example.lullaby`);
CI verifies analyze + test on **Linux only**; and README screenshots are pending.

The tracker is real and the data really does stay on the device. Anything with
*production crypto*, *a second device*, or *an app-store listing* attached is
still partial. Keep that line bright.

## 7. Why it's worth doing

Because the alternative — recording a baby's medical life on a stranger's server,
behind an account, for a business model — is the default, and it doesn't have to
be. The contribution is not a new algorithm. It is the demonstration that a
warm, genuinely useful baby tracker can be built with **no account, no server,
and no data exhaust**, and that "your child's data never leaves your phone" can
be a checkable architectural fact rather than a marketing line.

---

## References

- **WHO Child Growth Standards** — the percentile curves growth measurements are
  plotted against.
- **OWASP — CSV / Formula Injection** — the class of attack the export sanitizer
  neutralizes; see [reference/csv-export-safety.md](reference/csv-export-safety.md).
- **RFC 4180** — the CSV quoting rules the export follows.
- **ChaCha20-Poly1305 (RFC 8439)** — the AEAD protecting the encrypted backup.
- **Diátaxis** (Procida, D.) — the framework these [docs](README.md) follow.

*The code and comments referenced here were authored by an AI assistant and
describe what currently exists — take them with gratitude and a grain of salt, and
verify before relying.*
