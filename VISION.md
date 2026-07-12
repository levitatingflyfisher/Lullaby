# Vision

> The north star for Lullaby. If you (person or agent) are about to change
> something load-bearing, read this first — it says what must stay true and why.
> For *how it's built*, see [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md);
> for *why each decision was made*, [docs/adr/](docs/adr/).

## The one idea

**A newborn's data is the most intimate medical record a family will ever keep —
so it should live on the parents' phone and nowhere else.** Feeds, sleep,
diapers, weight, every medicine and vaccine: this is a stream of protected health
information about a person who cannot consent. Cloud baby-trackers turn that
stream into their asset. Lullaby doesn't. There is no account, no server, no
analytics. The data is on the device, and it stays there unless a parent
*deliberately* exports it.

Everything else — the timers, the charts, the WHO percentile curves, the doctor
summary — is in service of that one commitment: **be genuinely useful to two
exhausted parents at 3 a.m., without ever asking them to trust a stranger with
their child's data.**

## What this is

A **local-first Flutter app** — Android, iOS, Linux, and web — for tracking an
infant's day-to-day care. It records:

- **Feeding** — breast / bottle / solid, left-right side, volume (ml or oz),
  duration via a live timer.
- **Sleep** — nap or night, start/stop timer, location, duration history.
- **Diapers** — wet / dirty / both / dry, colour.
- **Growth** — weight, height, head circumference, plotted against WHO percentile
  curves for boys and girls.
- **Health** — medicine dose log and vaccination history.
- **Views** — a dashboard with quick-log buttons and a live-timer card, a
  monthly calendar, a filterable timeline, statistics charts, and a **doctor
  summary** you can hand over (or export as PDF/CSV) at an appointment.

Every log entry carries an optional free-text **notes** field — the place a
parent scribbles the context a chart can't hold ("fussy after this feed",
"slept through in the car"). Multiple babies are supported. Nothing here needs
the internet.

## Design commitments (do not break these)

These are the load-bearing beliefs Lullaby shares with the rest of OpenHearth,
in this app's voice. Breaking one is a design regression, not a feature. Each is
recorded as an [ADR](docs/adr/).

1. **Local-first, and here that means local-only by default.** All data lives in
   an on-device SQLite database (via Drift). The app makes **no network calls** in
   normal operation — no sync server, no telemetry endpoint, no ad SDK. Offline
   is not a mode; it is the whole design. ([ADR-0001](docs/adr/0001-local-first-no-account.md))
2. **No account, ever, for core functionality.** You open the app and use it.
   There is no sign-up, no email, no identity. The optional encrypted backup uses
   a **recovery seed phrase**, not a login — a key you hold, not an account we
   hold. ([ADR-0004](docs/adr/0004-encrypted-backup-seed-phrase.md))
3. **No ads, no tracking, no data sales — architecturally, not just as a promise.**
   There is no analytics dependency in the build. This is checkable: read
   `pubspec.yaml` and grep `lib/` for an HTTP client. You won't find one.
4. **Data leaves the device only when the parent makes it leave.** Two exits
   exist, both explicit and user-initiated: (a) an **export** (CSV/PDF) shared via
   the OS share sheet, and (b) an **encrypted backup file** the parent saves and
   carries. Nothing is transmitted automatically. See [docs/privacy-model.md](docs/privacy-model.md).
5. **A medical export must be safe to open.** The exported CSV is a medical
   record that will be opened in a spreadsheet. Free-text fields (a medicine name,
   a note) are neutralized so they cannot execute as spreadsheet formulas.
   ([ADR-0005](docs/adr/0005-csv-injection-safety.md))
6. **Genuine craft.** Clean Architecture (domain / data / presentation), Riverpod
   for state, high test coverage including golden tests for layout. Warm, not
   sterile — home-cooked software for a tender moment.

## Honest scorecard — built vs. aspirational

A guiding light has to tell the truth about where the light reaches. **Every line
of source and every comment in this repo was written by an AI assistant. Treat it
as an accurate record of what currently exists, offered with gratitude and a grain
of salt — not a specification and not guaranteed-correct.** If a comment and the
tests disagree, the tests win; if the tests and reality disagree, reality wins.
As of v1.0.0:

**Real, tested, load-bearing:**
- The full tracking spine — feeding, sleep, diaper, growth, medicine, vaccine —
  with an on-device Drift/SQLite database, feature-first Clean Architecture, and
  Riverpod controllers. Roughly 450 tests across ~75 files (unit, widget, golden).
- The dashboard, calendar, timeline, statistics charts, and doctor summary.
- **PDF and CSV export**, with the CSV formula-injection neutralization tested.
- **Encrypted backup/restore** to an `.ohbk` file: the app-side serialization,
  the OHBK wire format, the real audited crypto (`sanctuary_auth_core`), and
  the destructive-restore transaction are all real and tested — reachable
  from Settings in every build, not gated to release. (See the caveat below on
  where the crypto dependency lives, and the known pre-rewire-backup
  incompatibility in [docs/limitations.md](docs/limitations.md#known-incompatibility-pre-rewire-stub-era-backups).)
- CI runs `flutter analyze` and `flutter test` on every push and PR (Linux).

**Aspirational / partial — documented, not fully shipped:**
- **The audited crypto lives in sibling repos, not on pub.dev.** The
  encrypted-backup module (`sanctuary_auth_core`) and its UI layer
  (`sanctuary_backup_ui`) are consumed as path dependencies on sibling
  checkouts (`../packages/...`), cloned by CI and, for a local build, by hand
  (see README). This is a distribution/build-setup gap, not a feature gap —
  the crypto itself is real, not a stub. See
  [docs/reference/backup-format.md](docs/reference/backup-format.md) and
  [docs/privacy-model.md](docs/privacy-model.md).
- **A "named"/synced account tier** exists in the auth enum (`AuthTier.named`)
  but the app only ever runs the account-free **ghost** tier. Multi-device sync
  is not shipped.
- **Screenshots** in the README are still "coming soon."
- **Play Store / App Store release**: the `applicationId` is still
  `com.example.lullaby`; publishing needs a real identifier and signing key.
- CI verifies analyze + test on **Linux only** — iOS, Linux desktop, and web are
  supported targets but are not exercised by CI.

The tracker is real, the backup crypto is real, and the data really does stay
on the device. Anything with *a second device* or *an app-store listing*
attached is still partial. Keep that line bright.

## Horizons (problems, not a feature list)

Framed as problems on purpose — a dated feature list self-destructs.

- **Near** — Publish `sanctuary_auth_core`/`sanctuary_backup_ui` so the path
  dependency can become a normal pub.dev one (no sibling-clone step). Fill in
  the README screenshots. A guided first-run so a sleep-deprived parent logs
  their first feed in under a minute.
- **Mid** — The hardest honest problem: **how do two parents share one baby's
  record without a server?** Today the answer is "one device, or carry an
  encrypted backup between them." A real answer — encrypted-blob sync through a
  dumb relay, merge semantics for concurrent edits — is unbuilt and is where the
  local-first ethos gets genuinely difficult.
- **Far** — Data portability that outlives the app: an open, documented export
  format a parent can hand to a paediatrician's system or to the next tool, so
  the record is theirs for good.

## The name

**Lullaby** — the song you sing to settle a child to sleep. Quiet, repetitive,
for an audience of one, and never performed for a crowd. The app aims to be the
same: a calm, private companion for the small hours, not a stage.
