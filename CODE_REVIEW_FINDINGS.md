# Full-Codebase Review Findings — 2026-06-12

Five parallel deep-review passes covered the entire codebase: (1) database/core/app
shell, (2) tracking/dashboard/timeline/calendar, (3) growth/health/stats/doctor,
(4) sanctuary_backup/export/settings/babies/home_widget with a security focus, and
(5) the test suite and CI. Every finding below was verified against the actual code
(file:line cited); speculation and style nits were excluded. No Flutter SDK was
available during review, so nothing here is analyzer/test output — it is all from
reading the code.

## Verdict: fix in place, do not rewrite

All five passes independently reached the same conclusion: the clean-architecture
layering is real (DAOs → Result-returning repositories → Riverpod controllers),
migrations are additive and version-consistent, multi-baby SQL isolation is
correct in every DAO, the backup wipe-and-restore is genuinely transactional, and
seed-phrase hygiene is clean (no logging, no clipboard, disposed controllers).
The defects cluster at predictable seams — stream composition, the
single-active-X invariants, day-boundary arithmetic, platform configuration —
and each cluster is fixable with localized patches. A clean-room rewrite would
discard the parts that are right (most of them) to fix the parts that are wrong
(enumerated below).

---

## Resolution status (PR #1)

All fixes below were verified by a real CI gate (`flutter analyze` + 440+ tests)
after CI itself was repaired (it had never passed: the private crypto dependency
404'd at checkout and the pinned Flutter was too old for the SDK constraint).

**Fixed & CI-verified:** C1, C2, C3, H1, H2, H3, H4, H5, H6, H7, H8, H9, H10,
H12 (analyze gate added), M1, M2, M4, M5, M6, M7, M8 (doctor summary + growth
chart), M9, M10, M11, M12, M13, M14 (dead code removed), L1 (calendar/stats), L4.

**Self-review round (also CI-verified):** an adversarial four-angle review of
this branch's own diff found four real bugs — three regressions introduced by
the fixes themselves (open sleep session inflating historical sleep averages;
`deriveKeysFromPhrase` outside the restore try/catch; the active-baby timer
listener racing/permanently no-opping after a failed first load) plus a latent
gap (deleting the active baby left none active). All fixed, plus a new
`BackupController` test pinning the restore error→outcome mapping (the test
that would have caught the derive regression).

**Partially addressed:**
- H11 — CI no longer 404s (a vendored in-repo stub replaces the checkout), but
  the real package still needs a deploy token + pinned ref for true
  verification. The stub is CI-only and never ships.
- L11 — the recovery-words modal is now non-dismissible; `FLAG_SECURE`
  (screenshot blocking) still needs native work.

**Deferred (needs upstream/library change), flag for the integration debrief:**
- M3 — persisting a phrase entered during restore needs an
  encrypted-backup-auth-module method to import a known mnemonic; adding it
  would only be exercised against the CI stub, not the real package.

**Not yet done (good follow-ups):** H13 / M16 — broader controller-layer and
backup-widget test coverage (the `BackupController` restore-mapping test above
is a first slice; the systematic gap remains), M15 (restore-atomicity test),
FK partial-unique-active hardening (the invariant is procedural, not
DB-enforced), and the remaining lows (L2, L3, L5–L7, L10, L12–L16).

---

## CRITICAL — break core behavior or silently corrupt data

**C1. Timeline & dashboard activity streams freeze after the first emission.**
`lib/features/timeline/presentation/controllers/timeline_controller.dart:107-137`
`_buildEventStream` combines six infinite Drift `watch()` streams with nested
`asyncExpand`. `asyncExpand` pauses the source until the inner stream *completes*
— Drift watch streams never complete — so after the initial cascade only the
innermost (vaccine) stream propagates. The dashboard "Recent Activity" (from
non-autoDispose `allEventsProvider`) is frozen at its first snapshot for the
process lifetime; the Timeline refreshes only when a filter chip rebuilds the
provider. *Fix: combine with a real `combineLatest` (rxdart `Rx.combineLatest6`
or hand-rolled); never `asyncExpand` non-terminating streams.*

**C2. Adding a second baby bricks the app (multiple `isActive` rows).**
`lib/features/babies/presentation/controllers/baby_controller.dart:22-54,66-78`,
`lib/services/database/daos/baby_dao.dart:22-24`,
`lib/features/sanctuary_backup/data/backup_serializer.dart:88`
`createBaby` always inserts `isActive: true` and nothing deactivates the previous
baby until `setActiveBaby` is separately invoked. `watchActiveBaby()` uses
`watchSingleOrNull()` with no `limit(1)`, which emits a `StateError` into the
stream when two rows match — dashboard, timeline, charts, and calendar all drop
into their error branches at once. `setActiveBaby` itself updates rows one-by-one
with no transaction and ignores each `Result`, so a mid-loop failure persists the
broken state. The backup restorer also accepts `isActive` from foreign JSON
unvalidated. *Fix: enforce single-active in one transactional DAO statement
(`UPDATE babies SET is_active = (id = ?)`), add a partial unique index, make
`watchActiveBaby` deterministic (`orderBy` + `limit 1`), validate on restore.*

**C3. Foreign keys are never enabled; deleting a baby orphans all its data forever.**
`lib/services/database/database.dart:40-53`,
`lib/services/database/daos/baby_dao.dart:31-32`
SQLite requires `PRAGMA foreign_keys = ON` per connection; the
`MigrationStrategy` has no `beforeOpen` and no `customStatement` exists anywhere
in `lib/`. Every `references(Babies, #id)` is decorative and there is no
`ON DELETE` behavior. `deleteBaby` removes only the `babies` row, so all
feeding/sleep/diaper/growth/medicine/vaccine rows for that baby (including any
open `endTime == NULL` session) are stranded — invisible in the UI but exported
into every backup forever. *Fix: add `beforeOpen` pragma, cascade deletes (or
transactional child deletes in the DAO), and a v4 migration to clean existing
orphans.*

## HIGH

**H1. Privacy promise broken: plaintext DB is cloud-backed-up by default.**
`android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
No `android:allowBackup="false"`, no `dataExtractionRules`; `allowBackup`
defaults to true, so Android Auto Backup uploads the plaintext
`lullaby.sqlite` (a child's feeding/medicine/vaccine records) to the user's
Google account. iOS Documents dir is likewise iCloud-backed-up by default.
Settings says "All data stays on your device" (`settings_screen.dart:46`) and
the entire sanctuary design is that only *encrypted* blobs leave the device.
*Fix: `allowBackup=false` + `dataExtractionRules` (API 31+); exclude the DB via
`NSURLIsExcludedFromBackupKey` on iOS — or document the exception.*

**H2. Avatar photos reference image_picker's cache path — guaranteed to dangle.**
`lib/features/babies/presentation/screens/baby_edit_screen.dart:47-52`
`picked.path` (app cache / iOS tmp) is persisted verbatim; no copy into permanent
storage exists anywhere. The OS clears cache under pressure, iOS container paths
change on update/reinstall, and the absolute path is embedded in backups
(`backup_serializer.dart:31`) so it can never survive a cross-device restore.
*Fix: copy to `documents/avatars/<babyId>.jpg`, store a relative filename,
resolve at display time.*

**H3. Doctor summary computes percentile at the baby's current age against a
possibly months-old measurement.**
`lib/features/doctor/presentation/controllers/doctor_controller.dart:85-106`
A 6-month P50 weight evaluated at 11-month age bands reads as <P3–P15 — a wildly
wrong figure shown to a pediatrician and embedded in the export PDF. The
`ageMonths <= 24` gate also wrongly suppresses percentiles for a 25-month-old
measured at 23 months. *Fix: compute age from `measuredAt - dateOfBirth` and
gate on that.*

**H4. Stats periods are off by one with partial-day buckets.**
`lib/features/stats/presentation/controllers/stats_controller.dart:35-36`,
`lib/features/stats/domain/services/stats_aggregator.dart:39-40`
`end = now; start = end - 7d; current = start.startOfDay` yields **8** buckets
for "7d"; the DB query starts at now's time-of-day 7 days ago so day 1 is
systematically undercounted in every chart, and today's partial bucket is
averaged as a full day, dragging "Average per day" down on the doctor screen.
(Side effect: `feeding_trend_chart.dart:100` hides dots for "14d" because it
actually has 15 points.) *Fix: whole local-day buckets; treat today as partial
explicitly.*

**H5. Doctor-picked date range silently drops the entire final selected day.**
`lib/features/stats/domain/services/stats_aggregator.dart:40`,
`lib/features/doctor/presentation/screens/doctor_summary_screen.dart:234-242`
`showDateRangePicker` returns `end` at 00:00 of the last day; the aggregator and
DAO both treat `end` as exclusive, so "Jun 1 – Jun 7" aggregates Jun 1–6 in the
averages, the share text, and the CSV — while the header still says Jun 7.
*Fix: normalize the picked end to the start of the following day before storing.*

**H6. Duplicate active sessions are easy to create and impossible to stop.**
`lib/features/tracking/presentation/controllers/sleep_controller.dart:40-76`,
`feeding_controller.dart:37-74`,
`lib/features/tracking/presentation/screens/feeding_log_screen.dart:234-298`
`startSleep`/`startBreastFeeding` check neither in-flight state nor an existing
active row (contrast `DiaperController.quickLogWet`, which guards correctly).
Double-tap the dashboard quick-log → two open sleep rows; no race is needed for
feeding because the Stop UI keys off screen-local `_activeLogId` — leave and
re-enter the screen mid-feed and you get a Start button. Active-row lookups use
`limit(1)` with no `orderBy`, so the second open row can never be closed and is
rehydrated as a ghost timer on every launch. *Fix: controller-level
single-active-session guard; surface persisted active sessions in log screens;
`ORDER BY start_time DESC` + stale-session cleanup.*

**H7. `stopBreastFeeding` resolves the session via `getLastFeeding` and removes
the timer before the DB write.**
`lib/features/tracking/presentation/controllers/feeding_controller.dart:76-105`
If any bottle/solid feed was logged after the breast session started (normal:
partner feeds solids during a nursing timer), the last feeding isn't the breast
log, the update is skipped with `NotFoundFailure`, and the row stays open forever
— while the timer card has already vanished. A failed update strands the session
the same way. (`stopSleep` shares the remove-timer-first ordering flaw.) *Fix:
fetch by `logId`; remove the timer only after a successful write.*

**H8. Overnight sleep contributes zero to "today" everywhere.**
`lib/features/tracking/presentation/controllers/sleep_controller.dart:123-134`,
`lib/services/database/daos/sleep_dao.dart:45-53`, `stats_aggregator.dart:48-72`,
`calendar_controller.dart:66-74`
All aggregation attributes whole sessions to their start day via
start-time-only range filters. A 22:00→07:00 night sleep shows ~0 on the
dashboard "Sleep:" chip every morning — the flagship metric, wrong at exactly
the moment parents check it — and single day bars can exceed 24h. Sessions that
started before a range's start are excluded entirely. *Fix: split sessions at
local midnight during aggregation; fetch with overlap semantics
(`start < rangeEnd && (end ?? now) >= rangeStart`).*

**H9. Active timers are not baby-scoped.**
`lib/features/tracking/presentation/controllers/timer_controller.dart:19-47,64-119`
`ActiveTimer` has no `babyId` and rehydration runs once (latched) for the
startup-active baby. After switching babies: baby A's running nap shows on baby
B's dashboard; STOP looks up baby B's active sleep, fails, but the timer is
already removed (session stranded open); baby B's own persisted session is never
rehydrated. *Fix: store `babyId` on `ActiveTimer`, stop by logId, re-run
rehydration on active-baby change.*

**H10. Dashboard daily summary: 2 fresh DB queries per second during a timer,
zero refreshes otherwise.**
`lib/features/dashboard/presentation/screens/dashboard_screen.dart:27,257-277`
The whole screen rebuilds on every 1-second timer tick (it watches
`activeTimersProvider`), and `_DailySummary` constructs a new
`FutureBuilder(Future.wait([...]))` inline per build. With no timer running,
nothing ever recomputes — quick-logging a diaper doesn't update the "Diapers: N"
chip. *Fix: stream/invalidation-based summary provider keyed by babyId+day;
scope the timer watch to the timer-card subtree.*

**H11. CI checks out the encrypted-backup auth module sibling repo unpinned.**
`.github/workflows/ci.yml:25-28`
No `ref:` — every run builds against the floating default-branch tip of the
private auth module's repo. Non-reproducible CI, breakable with no Lullaby
change, and a supply-chain path straight into the crypto layer. *Fix: pin to a
tag/SHA and keep it in sync with the pubspec constraint.*

**H12. CI never runs `flutter analyze`.**
`.github/workflows/ci.yml`
The only gate is `flutter test`; `analysis_options.yaml` is unenforced and
effectively decorative. *Fix: add `flutter analyze --fatal-warnings` (and
consider `dart format --set-exit-if-changed`).*

**H13. The planned backup widget tests are mostly missing.**
`test/widget/features/sanctuary_backup/backup_settings_section_test.dart` vs
the backup integration test plan
Of the 4 planned widget tests only #1 exists; the seed-phrase modal, the
acknowledge re-entry interaction, and the restore-dialog-gates-import flow are
untested, `backup_controller.dart` has no tests at all, and the repo contains
zero `verify()` interaction assertions. *Fix: add interaction tests with mocked
controller/file-picker.*

## MEDIUM

**M1. All restore failures collapse to "Check your recovery words."**
`backup_controller.dart:97-118`, `backup_settings_section.dart:212`
`BackupSchemaException` (too-new backup → "update the app"),
`BackupFormatException` (corrupt file), and `CryptoException` (actual wrong
phrase) are indistinguishable; a user with a too-new backup will retype their
correct words forever. Violates the integration spec's "legible error" success
criterion. *Fix: catch the four types separately, distinct messages.*

**M2. Restore with an existing key never prompts for a phrase.**
`backup_settings_section.dart:192-197`
A backup exported under a different phrase (other device, pre-reset, partner's
phone) always fails to decrypt and the only escape is danger-zone "Reset
identity". Spec says prompt unconditionally. *Fix: fall back to a phrase prompt
on decrypt failure (or always offer it).*

**M3. `restoreWithPhrase` never persists the entered phrase.**
`backup_controller.dart:105-119`
After the flagship uninstall→reinstall→restore flow, `hasKey` is still false and
Settings offers to generate a **new** phrase — the user ends up with two phrases
opening different backups. *Fix: persist the entered phrase via the library
after successful restore.*

**M4. No app-state refresh after a destructive restore.**
`backup_controller.dart:80-119`
In-memory timers keep referencing wiped rows (STOP then fails, ghost timers
persist), the rehydration latch prevents picking up restored in-progress
sessions, and the home widget shows pre-restore data until next resume. *Fix:
clear/rehydrate `activeTimersProvider`, `triggerUpdate()` the widget, invalidate
cached FutureProviders after restore.*

**M5. Android home-widget chronometer never displays on modern devices.**
`lib/features/home_widget/.../home_widget_service.dart:42-44`,
`android/.../LullabyWidgetProvider.kt`
Dart writes offset-less local-time ISO strings; Kotlin parses with
`Instant.parse` (throws → row hidden) on API ≥ 26 and misparses local-as-UTC on
older devices. *Fix: write `toUtc().toIso8601String()`.*

**M6. Home widget is blanked on every cold start.**
`lib/app/app.dart:25-27`
The post-frame `triggerUpdate()` races `activeBabyProvider` (still loading),
writes `'–'`/nulls with `babyId: ''`, and isn't re-triggered when the stream
emits. *Fix: trigger from the provider's first data event.*

**M7. Percentiles snap to the nearest month with no age interpolation.**
`lib/features/growth/domain/entities/who_percentile_data.dart:29-34`
A 2-week-old is evaluated against month-1 bands (median moves 3.3→4.5 kg in that
month) — early-infancy percentiles can be off by tens of points. *Fix:
interpolate band values between floor/ceil month before percentile
interpolation.*

**M8. Null gender silently uses boys' WHO tables.**
`growth_curve_chart.dart:44`, `doctor_controller.dart:87`
`gender ?? Gender.male` shifts a 12-month girl's percentile 15–20 points with no
indication. *Fix: omit percentiles (or prompt) when gender is unset.*

**M9. Stats, doctor, and calendar providers are stale snapshots.**
`stats_controller.dart:30-39`, `doctor_controller.dart:51-52`,
`calendar_controller.dart:26-88,116-145`
Non-autoDispose `FutureProvider.family`s over one-shot `get()`s with
`DateTime.now()` captured at build: new logs (or the day rolling over) never
refresh the stats screen, doctor summary, calendar markers, or day sheet for the
rest of the session. *Fix: autoDispose + invalidate-on-write, or derive from the
existing watch streams.*

**M10. Day-bucket iteration breaks on DST transitions.**
`stats_aggregator.dart:39-41,88`
`current.add(Duration(days: 1))` adds 24 wall-clock hours: fall-back days get a
double-counted hour and a duplicate date bucket; after spring-forward every
bucket starts at 01:00 and 00:00–01:00 events are dropped. *Fix: advance with
`DateTime(y, m, d + 1)`.*

**M11. Unparseable medicine dosage is silently discarded.**
`medicine_add_screen.dart:83-85` (same pattern in `vaccine_add_screen.dart`)
No validator; `2,5` (comma-decimal locales) or `5 ml` saves the medicine
**without a dosage**, no error shown — safety-relevant data loss. *Fix:
validator + comma normalization.*

**M12. Clock changes persist negative durations and render garbage timers.**
`sleep_controller.dart:93-99`, `feeding_controller.dart:85-97`,
`core/extensions/duration_extensions.dart:9-14`
Stop paths store `now - startTime` with no floor; display renders `00:-1:-30`.
*Fix: clamp at zero; reject `endTime < startTime` in controllers (edit screens
already do).*

**M13. No indices on any child table.**
`lib/services/database/tables.dart`
Every hot query filters `babyId` and sorts by time over tables that grow by
thousands of rows/year, re-scanned on every write via watch streams. *Fix:
`(baby_id, time)` indices in the v4 migration.*

**M14. `hasBabyProvider` is dead code; the documented onboarding gate doesn't exist.**
`core/providers/bootstrap_provider.dart:8-15`, `app/router.dart:25-27`
Referenced nowhere; router has no redirect; fresh installs land on a dashboard
with no baby. Also conflates DB failure with "no babies" and would cache `false`
forever. *Fix: wire a redirect off a baby-existence stream, or delete it.*

**M15. Restore-failure atomicity is untested.**
The single most important untested path: a payload that passes the schema check
but fails mid-insert, asserting the wipe rolls back. (Code review confirmed the
transaction does cover the wipe — see "verified sound" below — but no test pins
it.) Also untested: the phrase-derived (PBKDF2) export→restore round-trip the
integration doc planned; repository tests use raw deterministic keys.

**M16. The controller layer is systematically untested.**
13 of 14 feature controllers have no tests (medicine's add-screen recording-fake
test shows the house pattern — it's just not applied elsewhere); tracking
save-flows assert only titles/icons. The suite would catch persistence/export
regressions but not state-management or backup-UI ones. `analysis_options.yaml`
is stock flutter_lints with `unawaited_futures`/`discarded_futures`/strict modes
off.

## LOW

- **L1.** `endOfDay` (23:59:59.999) + exclusive `<` + Drift's second-precision
  storage drops the last second of every day (`core/extensions/date_extensions.dart:18`
  + every `getInRange` DAO). Standardize on half-open ranges ending at next
  midnight; delete `endOfDay`.
- **L2.** Count queries materialize full rows (`diaper_dao.dart:41-61`) instead
  of `SELECT COUNT(*)`.
- **L3.** Active-session lookups use `limit(1)` without `orderBy` —
  nondeterministic row choice (`sleep_dao.dart:24-43`, `feeding_dao.dart:31-38`).
- **L4.** Timeline sort is unstable; same-second events jitter across reloads
  (`timeline_controller.dart:129`). Add type/id tie-break.
- **L5.** Bottle amount unvalidated in edit mode: `-50` persists, junk silently
  nulls (`feeding_log_screen.dart:84-87`).
- **L6.** Dashboard snackbars report success without awaiting the result
  (`dashboard_screen.dart:196-209`).
- **L7.** Theme choice resets every launch — `ThemeController` is in-memory
  only; no persistence dependency exists (`theme_controller.dart:7-22`).
- **L8.** Restore phrase normalization is trim-only: internal whitespace/case
  pass the 12-word check but derive a different key
  (`phrase_entry_dialog.dart:87-93`). Normalize to lowercase single-spaced.
- **L9.** `recordBackupCompleted()` fires before the share sheet — cancelling
  the share still updates "Last backup" (`backup_controller.dart:67`,
  `backup_settings_section.dart:169-172`).
- **L10.** Baby name interpolated unsanitized into export file paths (`/` in a
  name → unhandled `FileSystemException`); CSV cells aren't formula-escaped
  (`=`/`+`/`@` prefixes execute in Excel/Sheets)
  (`export_bottom_sheet.dart:36-62`, `export_service.dart:88-95`).
- **L11.** Seed-phrase modal is barrier-dismissible and has no FLAG_SECURE —
  words appear in screenshots/recents thumbnails
  (`backup_settings_section.dart:123-130`, `seed_phrase_modal.dart`).
- **L12.** Growth chart Y-bounds computed from percentile bands only — preemie
  weights plot invisibly outside the clip rect; >24-month records silently
  dropped from the chart but not the list (`growth_curve_chart.dart:100-132`).
- **L13.** "Upcoming" vaccines render in arbitrary order (sorted by
  always-NULL `administeredDate`); overdue ones aren't flagged
  (`vaccine_dao.dart:36-42`, `vaccine_screen.dart:63-66`).
- **L14.** `photoPath` from a backup is written unvalidated, and
  `baby_switcher_sheet.dart:42-44` / `baby_edit_screen.dart:77-79` build
  `FileImage` without an existence check (`baby_avatar.dart` checks — copy it).
- **L15.** Vacuous tests: `home_widget_controller_test.dart` (type-echo only —
  the feature's sole controller test), `baby_test.dart:18-22` (`isNotEmpty` on a
  method that can't return empty, asserting the wrong age branch),
  `summaries_in_range_provider_test.dart:127-137` (type echo).
- **L16.** README claims "326 test cases across 48 files"; actual ≈ 437 across
  66. `backup_serializer_test.dart` hardcodes `schemaVersion == 3` (acceptable
  tripwire; diverges from plan wording). The Settings screen test passes even
  when the backup section silently collapses to nothing
  (`backup_settings_section.dart:26` swallows errors into `SizedBox.shrink`).

---

## Verified sound (so fixes don't re-litigate them)

- Backup restore wipe + insert share one transaction — malformed payloads roll
  back and existing data survives; FK-safe ordering; older-version backups parse
  (missing tables → empty); future versions rejected via `BackupSchemaException`.
- Seed-phrase hygiene: no print/log/analytics/clipboard anywhere; phrase travels
  by constructor/dialog return only; text controllers disposed; export reuses
  the in-memory master key per spec.
- Timers derive elapsed time from persisted `startTime` (survives process
  death); rehydration exists with logId dedupe; `Timer.periodic` is cancelled on
  dispose and when the last timer stops.
- Every DAO query in all seven DAOs filters by `babyId`; deletes are by primary
  key; no cross-baby SQL leak (H9 is in-memory state, not SQL).
- Migrations: v1→v3 ladder is additive and consistent; one-hop upgrades work.
- WHO percentile table data matches published standards within rounding;
  out-of-band percentiles clamp to 1.0/99.0 instead of extrapolating.
- Export temp files go to the app-private cache and are deleted in `finally`;
  `.ohbk` is shared from memory; raw CSV deliberately omits notes; PDF unit
  conversions (kg→lb, cm→in) are correct.
- No INTERNET permission, no hardcoded secrets; CI has minimal permissions, no
  secrets exposure to fork PRs, and genuinely fails on test failure.
- Per-test in-memory Drift DBs with clean teardown across all 14 DB-backed test
  files; serializer/export/DAO/timer-rehydration coverage is strong.

## Suggested fix workstreams

Ordered by user harm; each is one reviewable PR.

1. **Data integrity (C2, C3, M13, L3):** FK pragma + cascade, transactional
   single-active-baby invariant + partial unique index, v4 migration with
   indices and orphan cleanup, deterministic active-row lookups.
2. **Privacy & platform (H1, H2, M5, M6, L11):** `allowBackup=false` +
   `dataExtractionRules` + iOS backup exclusion; avatar copy-to-documents with
   relative paths; home-widget UTC timestamps + cold-start trigger; FLAG_SECURE
   on the phrase modal.
3. **Live data freshness (C1, H10, M9):** replace `asyncExpand` with
   combineLatest; stream-derived dashboard summary; autoDispose/invalidate
   stats, doctor, and calendar providers.
4. **Sessions & timers (H6, H7, H9, M12, L6):** single-active-session guards,
   stop-by-id after successful write, baby-scoped timers with re-rehydration,
   zero-clamped durations.
5. **Time arithmetic (H4, H5, H8, M10, L1):** midnight-splitting overlap
   aggregation, whole-day buckets, calendar-day stepping, half-open ranges,
   inclusive picker end.
6. **Doctor & health correctness (H3, M7, M8, M11, L12, L13):**
   measurement-age percentiles, age interpolation, explicit null-gender
   handling, dosage validation, chart bounds, vaccine ordering.
7. **Backup UX & identity (M1–M4, L8, L9, L14):** distinct error messages,
   phrase-prompt fallback, persist phrase after restore, post-restore state
   refresh, phrase normalization, share-confirmed backup timestamps.
8. **CI & tests (H11–H13, M15, M16, L15, L16):** pin the sibling checkout, add
   `flutter analyze`, restore-atomicity and phrase round-trip tests, the
   missing backup widget tests, controller-layer tests on the medicine-screen
   pattern, stricter lints.

Workstreams 1–2 are release-blocking. 3–5 fix what users see daily. 6 fixes
wrong numbers shown to doctors. 7–8 harden the backup story before the
integration recipe is copied to the next app.
