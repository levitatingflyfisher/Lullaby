# AGENTS.md

Guidance for AI coding agents (and humans) working in this repo. This is the
top-level map; when in doubt, the docs it points to go deeper.

**Read these three, in order, before non-trivial work:**
1. [VISION.md](VISION.md) — what must stay true and why (the design commitments).
2. [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md) — how it fits together, with diagrams.
3. [docs/adr/](docs/adr/) — why each load-bearing choice was made (read before re-litigating one).

## Take the code as current-state, not gospel

Every line of source and every comment here was written by an AI assistant. Treat
it as **an accurate record of what currently exists, offered with gratitude and a
grain of salt** — not as a specification and not as guaranteed-correct. A comment
claiming an invariant is a *hypothesis to verify*, not a proof. If a comment and
the tests disagree, the tests win; if the tests and reality disagree, reality
wins. When you rely on a claim, confirm it (read the code, run the test) first.

## What this is

A **local-first Flutter baby tracker** — feeding, sleep, diapers, growth (WHO
percentiles), medicine, vaccines, plus a dashboard, calendar, timeline,
statistics, and a doctor summary with PDF/CSV export and optional encrypted
backup. On-device SQLite (Drift), Riverpod state, Clean Architecture. No account,
no network calls in normal operation. Roughly 570 tests across ~97 files.

## Non-negotiables (breaking one is a regression, not a feature)

- **No account, no telemetry, no ad SDK, no analytics.** Do not add a network
  dependency for anything the app does on its own. Data leaves the device only by
  an explicit, user-initiated export, encrypted backup, or sync a parent turned
  on. The network paths are `hearth_sync`'s relay client and its same-Wi-Fi
  listener/client (`listenOnWifi` / `syncOnWifi`), reached only through
  `HouseholdSync` once sync is on; `household_sync_off_test.dart` pins that the
  off path loads no kernel, makes no client and opens no port. The Wi-Fi
  screens sit behind a conditional import (`wifi_sync.dart`), so the QR code
  and LAN client never reach the web bundle. ([ADR-0001](docs/adr/0001-local-first-no-account.md), [ADR-0007](docs/adr/0007-household-sync.md))
- **Every write to a synced table goes through `RecordWriter`.** Never write a
  record table with a DAO insert/update/delete: with sync on that write would
  never reach the log, and the next change from the other phone would undo it.
  Updates send only changed fields; Undo is `restore…`, never a re-create. A
  synced field's name and type are permanent (ADR-0007): add, never rename.
- **The exported CSV must stay formula-injection-safe.** Any new field written
  into a CSV export must go through the cell-sanitizing path (`_csvCell` in
  `export_service.dart`). A free-text value must never be able to execute as a
  spreadsheet formula. ([ADR-0005](docs/adr/0005-csv-injection-safety.md))
- **Restore is destructive and transactional.** `BackupSerializer.restoreAll`
  wipes existing data inside a single transaction before inserting. Don't make it
  partial-apply; a half-restored medical record is worse than a failed one. While
  sync is on, restore is refused (`RestoreWhileSyncingException`): it cannot be
  one step through the log.
- **Foreign keys are enforced.** The DB opens with `PRAGMA foreign_keys = ON`
  (see `database.dart`). Insert parents before children; delete children before
  parents. The v4 migration cleans orphaned rows — keep it. With sync on, a record
  can arrive before its baby: `RecordProjection` parks it in `sync_parked_rows`
  and lands it with the baby, and must never throw on kernel input.
- **TDD, always.** Reproduce → failing test → fix → `flutter test` green → commit.
  Every bugfix ships with a regression test (unit or widget). Layout changes get
  a golden test.
- **Atomic commits, one concern each.** Commit messages state the *why*. **No AI
  attribution trailers** in commit messages — deliberate project policy.
- **Never commit** `docs/superpowers/` (local plans/specs) or the per-tool agent
  scratch guides (the ignored top-level `*.md` working notes) — they're gitignored
  working artifacts. The committed contributor guide is this file.
- **The Android identity is `com.openhearth.lullaby`.**
- **CI checks this repo out into a `Lullaby/` working directory** (so the
  sibling `packages/` clones resolve at `../packages/`). Every workflow step
  that runs Flutter needs `working-directory: Lullaby` — a step without it
  fails with "No pubspec.yaml file found".

## Where things are (progressive disclosure)

Full detail in [OVERVIEW.md § Module map](docs/architecture/OVERVIEW.md#module-map--where-to-look).
The short version, by concern:

| You're touching… | Go to |
|---|---|
| **The data schema** (tables, columns, migrations, indices) | `lib/services/database/tables.dart`, `lib/services/database/database.dart`, `lib/services/database/daos/*` |
| **A tracker** (feeding / sleep / diaper) | `lib/features/tracking/` — `domain/` entity, `data/` repo impl, `presentation/` screen+controller |
| **Growth / WHO percentiles** | `lib/features/growth/` (`who_percentile_data.dart` holds the curves) |
| **Health** (medicine / vaccine) | `lib/features/health/medicine/`, `lib/features/health/vaccine/` |
| **Aggregation / stats** | `lib/features/stats/domain/services/stats_aggregator.dart`, `lib/features/stats/` |
| **Export (CSV / PDF)** | `lib/features/export/export_service.dart` (`_csvCell` is the safety fn) |
| **Encrypted backup** | `lib/features/sanctuary_backup/`; real crypto sibling `../packages/sanctuary_auth_core/`, UI sibling `../packages/sanctuary_backup_ui/` |
| **State wiring / providers** | `lib/core/providers/` (`database_provider.dart`, `repository_providers.dart`, `auth_providers.dart`) |
| **Navigation / theme / shell** | `lib/app/router.dart`, `lib/app/theme/`, `lib/app/shell_screen.dart` |
| **Native vs. web DB connection** | `lib/services/database/connection/` (`native.dart`, `web.dart`, conditional `connection.dart`) |
| **Two-phone sync** | `lib/features/sync/` — `data/lullaby_records.dart` (what syncs, the permanent schema), `record_writer.dart` (the write seam), `record_projection.dart` (kernel changes → Drift), `household_sync.dart` (lifecycle, relay loop, same-Wi-Fi sync, Forget, the gap-delete replay); `presentation/` (Settings → Sync with another phone, review list, `wifi_sync_io.dart` Show / Type a code, `wifi_sync_stub.dart` the browser's line). Kernel: sibling `../hearthSync/flutter/hearth_sync` |
| **Handoff notes** | `lib/features/handoff/` (Home's "Note for the next shift") |

Docs are organized [Diátaxis](https://diataxis.fr/)-style — see [docs/README.md](docs/README.md)
for the tutorials / how-to / reference / explanation split.

## How to work here

```bash
flutter pub get            # resolve deps (backup-crypto siblings must be cloned at ../packages/ — see README)
flutter analyze            # static analysis — must be clean (config: analysis_options.yaml)
flutter test               # the suite — must be green before you commit
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code after editing tables.dart
```

- **The two-phone tests** (`test/sync/`) run two phones through the real
  relay over localhost. Build the host kernel and the relay first, from
  `../hearthSync`: `(cd flutter/hearth_sync/rust && CARGO_TARGET_DIR=$PWD/target cargo build --release)`
  and `CARGO_TARGET_DIR=$PWD/target cargo build --release -p hearth_sync_relay`
  (or set `HEARTH_SYNC_LIB` / `HEARTH_RUST_RELAY`). A missing build fails the
  test. `LULLABY_SYNC_SCRATCH` moves the relay's scratch store (default
  `build/sync-relay-test`). `wifi_test.dart` needs only the bridge: two phones
  over a real loopback socket, no relay.
- **The web build** needs the kernel's WASM in `web/pkg/`: run
  `tool/build_web.sh` instead of a bare `flutter build web`.
- **Flutter ≥ 3.10.7 / Dart ≥ 3.10.7** (pubspec `environment`). CI pins Flutter
  `3.44.2` (an older channel shipped Dart 3.7.2 and failed resolution — see the
  comment in `.github/workflows/ci.yml`).
- **Drift codegen**: after any change to `tables.dart` or a DAO's queries,
  regenerate the `*.g.dart` files with `build_runner`. Never hand-edit generated
  code.
- **The backup crypto is a sibling package, not in-repo.** `pubspec.yaml`'s
  `sanctuary_auth_core`/`sanctuary_backup_ui` path dependencies point at
  `../packages/sanctuary_auth_core`/`../packages/sanctuary_backup_ui` —
  sibling checkouts, not a stub. Clone them next to `Lullaby/` before running
  `flutter pub get` (see README's sibling-clone commands). A pre-rewire
  (CI-stub-era) exported `.ohbk` file is a known, documented incompatibility
  with the real KDF — see
  [docs/limitations.md](docs/limitations.md#known-incompatibility-pre-rewire-stub-era-backups).
  See also [docs/reference/backup-format.md](docs/reference/backup-format.md).
- **Adding a feature**: mirror the existing shape — a folder under `lib/features/`
  with `domain/` (entity + abstract repo), `data/` (Drift-backed impl), and
  `presentation/` (screen + Riverpod controller). Register the repo provider in
  `core/providers/repository_providers.dart` and the route in `app/router.dart`,
  and give the route a visible, labelled caller from where a parent would look
  for it — `test/unit/app/router_doors_test.dart` fails on a route nothing
  navigates to. See [CONTRIBUTING.md](CONTRIBUTING.md).

## When you're unsure

Prefer a failing test to a plausible fix. Prefer matching the surrounding feature
to introducing a new pattern. On anything that touches **what leaves the device**
(a new dependency, an export field, the backup path), stop and check it against
[docs/privacy-model.md](docs/privacy-model.md) — that boundary is the product.
When in doubt about a decision's rationale, grep [docs/adr/](docs/adr/) before
reopening it; you may be re-litigating a settled trade-off.
