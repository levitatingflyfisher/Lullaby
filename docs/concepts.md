# Concepts

The ideas and domain model behind Lullaby, in prose. For the exact schema see
[reference/data-model.md](reference/data-model.md); for how the layers fit, see
[architecture/OVERVIEW.md](architecture/OVERVIEW.md).

## The baby is the root

Everything is scoped to a **baby**. A baby has a name, date of birth, optional
gender and avatar photo, and an `isActive` flag. The app tracks one **active
baby** at a time (the switcher sheet changes it); every log, chart, and summary
you see is for that baby. Families with more than one child add another baby and
switch between them. When foreign-key enforcement was turned on (schema v4),
child rows orphaned by a deleted baby are cleaned up and the "multiple active
babies" state is collapsed to one — see the migration in `database.dart`.

## The records

Six kinds of record hang off a baby, each a domain **entity** with a matching
SQLite table:

- **Feeding** — type (breast / bottle / solid), a start (and optional end) time,
  duration, left/right/both side, and amount in ml *and* oz.
- **Sleep** — nap or night, start/end, duration, location.
- **Diaper** — wet / dirty / both / dry, plus colour.
- **Growth** — weight (kg), height (cm), head circumference (cm), at a measured
  time — the inputs to the WHO percentile curves.
- **Medicine** — a name, dose and unit, administered time.
- **Vaccine** — a name, dose number, scheduled and administered dates, provider.

Every record also carries an optional free-text **`notes`** field — the place a
parent records the context a structured field can't hold. There is no separate
"handoff" record; the notes field *is* the shared scratch space between whoever
is caring for the baby.

## Timers and quick logging

Two of the trackers (feeding, sleep) are naturally **live sessions**. The
`timer_controller` models an in-progress session so a parent can start a feed or
a nap with one tap, put the phone down, and stop it later — the dashboard's
active-timer card shows what's running. The dashboard's quick-log buttons exist
so the most common actions are one tap from launch, which is the whole point at
3 a.m.

## Reads are reactive; errors are typed

Repositories expose Drift **`Stream`s** (`watch…`) for anything the UI shows
live, so logging a feed updates the dashboard, timeline, calendar, and stats
without a manual refresh. One-shot reads and writes return a **`Result<T>`**
(`Success` / `Err(Failure)`, from `lib/core/errors/`): a database error becomes a
typed value the controller handles, not an exception that escapes to the UI.

## Derived views: stats and the doctor summary

Nothing in the derived views is stored separately — they are computed from the
records on demand:

- **Statistics** — the `stats_aggregator` rolls raw logs into a `DailySummary`
  per day (feed count and minutes, sleep minutes, diaper counts by type) over a
  chosen window (7 / 14 / 30 days), which the charts render.
- **Doctor summary** — a read-model assembled for an appointment: recent
  averages, the latest growth with WHO percentiles, recent medicines, and
  administered vaccines. It is what the PDF/CSV export renders.

## WHO percentile curves

Growth measurements are plotted against **WHO child-growth standard** percentile
curves (`who_percentile_data.dart`), separately for boys and girls. These are
reference curves for orientation, not a diagnosis — see
[limitations.md](limitations.md).

## Ghost tier and the encrypted backup

The app runs in a single account-free **ghost** tier: zero identity, zero server.
The only optional identity-adjacent concept is a **recovery seed phrase** — a
12-word phrase from which an encryption key is derived. It is not a login; it is
the key to your own encrypted backup file. A parent who sets one up can export an
encrypted `.ohbk` backup and restore it later or on another device. See
[privacy-model.md](privacy-model.md) and
[reference/backup-format.md](reference/backup-format.md).
