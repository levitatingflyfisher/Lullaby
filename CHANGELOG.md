# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Fleet conformance suite (`oh_fleet_conformance` dev dependency +
  `test/fleet_conformance_test.dart`): Lullaby's recorded posture is
  tokens-tier style, ZERO Android permissions (the empty set is an
  enforced claim, both directions), backup on the shared retention
  package, and size budgets. `budgets.json` records the baselines
  (gzipped `main.dart.js` + arm64 release APK, +5%) so size regressions
  fail the suite on any machine that has built the artifacts — the
  ratchet bites on local and deploy builds. (CI runs no build step, so
  the size check skips there by design; a CI build step is deliberately
  deferred.)
- CI clones the `ohStyle` and `ohFleetConformance` sibling repos so the
  workflow covers every path dependency the pubspec declares.

### Changed
- `test/flutter_test_config.dart` re-synced to the fleet-canonical
  variant: per-family font-load isolation (one font family failing to
  load no longer aborts the families after it). The success path is
  identical — all goldens verified byte-identical.
- `test/flutter_test_config.dart` replaced with the fleet-canonical
  FontManifest-aware variant (byte-identical across Trellis/Reckon/
  StillLife). All goldens re-rendered byte-identically — Lullaby bundles
  no custom text fonts, so nothing visual changed.
- Depend on the shared `openhearth_design` package (path dep, v0.4.0) as
  conformance readiness. A sweep of `lib/` found ZERO literals equal to
  canonical OpenHearth token values, so no colors were rewired and nothing
  visual changed; a readiness test pins the canonical token values and
  proves Lullaby's signature periwinkle (`0xFF7B8FD4`) is app-local
  identity, not a canonical token. Lullaby's type ladder and its
  Material-You dynamic-color hook remain untouched by design.
- Snapshot vault ("Previous backups"): every export and every restore now
  leaves a stamped on-device snapshot (keep-10, pinnable) you can restore,
  pin or delete from Settings.
- Mandatory pre-restore snapshot: a restore refuses to run unless the
  current data was snapshotted first — restoring is now reversible.
- Preview before restore: the confirm dialog shows the backup's age and
  per-table row counts next to what's on the device now.
- Every export verifies itself by read-back before reporting success.
- Plain-JSON export (unencrypted, honestly labeled) from Settings.
- Silent freshness snapshot when the newest one is older than 7 days.

### Fixed
- Doctor summary: a baby with no recorded sex now gets the honest WHO
  notes it was promised. The out-of-range note (measurement beyond the
  0–24 month tables) no longer depends on a recorded sex, and when the
  measurement IS in range a new note names the actual blocker —
  "WHO percentiles need a recorded sex" — on screen and in the PDF
  export, instead of silently omitting percentiles.
- WHO percentile interpolation returns the documented null instead of
  crashing when handed a band map missing a canonical band (3/15/50/
  85/97).
- Fresh-install restore with recovery words now adopts those words as the
  device identity — previously the restored data was orphaned and a new
  export required minting a new identity that didn't match the user's
  written-down phrase.
- Web (PWA): baby photos and data exports no longer crash. Five UI files
  bare-imported `dart:io`, which compiles on web but throws at runtime —
  avatars broke as soon as a baby had a photo set, and every export tap
  crashed. Photos now resolve through a platform trio (initial-letter
  avatar + honest "photos are available in the Android app" copy on web);
  CSV/PDF exports share bytes via the Web Share API with a plain-download
  fallback, so they genuinely work in every browser. A suite-level guard
  now fails CI if a bare `dart:io` import ever reappears in shared code.
- WHO growth percentiles are honest at the edges: a measurement outside
  the 0–24-month tables now shows a calm "outside that range" note
  (screen + PDF) instead of silently scoring against the 24-month curves;
  a measurement matching no band (e.g. NaN) no longer reports a fabricated
  50th percentile; degenerate equal-band interpolation can no longer
  produce NaN. In-range math is regression-locked byte-identical.

---

## [1.0.0] - 2026-02-24

### Added

**Tracking**
- Feeding log with breast, bottle, and solid feed types; left/right side toggle; live elapsed timer
- Sleep log with start/stop timer and duration history
- Diaper log with wet, dirty, and mixed change types
- Quick-log buttons on the dashboard for one-tap entry
- Active timer card on the dashboard showing an in-progress session

**Growth**
- Weight, height, and head circumference measurements
- Growth curves chart plotting measurements against WHO percentile data (boys and girls)

**Health**
- Medicine dose log (name, dose, unit, time)
- Vaccination history with date and vaccine name

**Statistics**
- Feeding trend chart (volume / session count over time)
- Sleep pattern chart (total sleep per day)
- Diaper frequency chart
- Configurable time period selector (7 days, 14 days, 30 days)

**Calendar**
- Monthly calendar view with event markers per day
- Day event sheet listing all activity for a selected date

**Timeline**
- Scrollable reverse-chronological activity feed
- Filter chips for feeding, sleep, diaper, growth, medicine, and vaccine events

**Dashboard**
- Daily summary strip (feed count, sleep total, diaper count)
- Recent activity list

**Baby profiles**
- Name, date of birth, and avatar photo
- Multiple baby support with a switcher sheet
- Age display (newborn / days / months / years)

**Doctor summary**
- At-a-glance summary of recent activity, growth measurements, and upcoming vaccinations

**Settings**
- Theme mode selector (system / light / dark)

**Architecture & Infrastructure**
- Clean architecture with feature-based folder structure
- Riverpod 2.x state management throughout
- Drift ORM on SQLite for local, offline-first data persistence
- go_router navigation with tab shell and modal routes
- Material 3 dynamic colour theming (Android 12+)
- 326 unit and widget tests; zero static analysis issues
- Android, iOS, and Linux platform support
