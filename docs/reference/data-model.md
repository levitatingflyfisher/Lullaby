# Reference: data model

The complete on-device schema. Defined in
[`lib/services/database/tables.dart`](../../lib/services/database/tables.dart);
migrations and indices in
[`lib/services/database/database.dart`](../../lib/services/database/database.dart).
**Current schema version: 4.**

All primary keys are `TEXT` UUIDs (from the `uuid` package). Every child
table references `babies.id`; **foreign keys are enforced** (`PRAGMA foreign_keys
= ON`). Drift stores `DateTime` as Unix milliseconds (integer). `createdAt` /
`modifiedAt` are audit timestamps on every table.

## `babies` (the root)

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | primary key |
| `name` | TEXT | length 1–100 |
| `date_of_birth` | DATETIME | |
| `gender` | TEXT? | drives boys/girls WHO curves |
| `photo_path` | TEXT? | on-device avatar path |
| `is_active` | BOOL | default `true`; exactly one baby is active at a time |
| `created_at`, `modified_at` | DATETIME | |

## `feeding_logs`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | primary key |
| `baby_id` | TEXT | → `babies.id` |
| `type` | TEXT | `breast` \| `bottle` \| `solid` |
| `start_time` | DATETIME | |
| `end_time` | DATETIME? | |
| `duration_minutes` | INT? | |
| `side` | TEXT? | `left` \| `right` \| `both` |
| `amount_ml` | REAL? | |
| `amount_oz` | REAL? | |
| `notes` | TEXT? | free text |
| `created_at`, `modified_at` | DATETIME | |

## `sleep_logs`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | primary key |
| `baby_id` | TEXT | → `babies.id` |
| `start_time` | DATETIME | |
| `end_time` | DATETIME? | |
| `duration_minutes` | INT? | |
| `type` | TEXT | `nap` \| `night` |
| `location` | TEXT? | |
| `notes` | TEXT? | free text |
| `created_at`, `modified_at` | DATETIME | |

## `diaper_logs`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | primary key |
| `baby_id` | TEXT | → `babies.id` |
| `time` | DATETIME | |
| `type` | TEXT | `wet` \| `dirty` \| `both` \| `dry` |
| `color` | TEXT? | |
| `notes` | TEXT? | free text |
| `created_at`, `modified_at` | DATETIME | |

## `growth_records`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | primary key |
| `baby_id` | TEXT | → `babies.id` |
| `measured_at` | DATETIME | |
| `weight_kg` | REAL? | |
| `height_cm` | REAL? | |
| `head_circumference_cm` | REAL? | |
| `notes` | TEXT? | free text |
| `created_at`, `modified_at` | DATETIME | |

## `medicine_logs`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | primary key |
| `baby_id` | TEXT | → `babies.id` |
| `medicine_name` | TEXT | free text (exported CSV sanitizes this) |
| `dosage` | REAL? | |
| `dosage_unit` | TEXT? | |
| `administered_at` | DATETIME | |
| `notes` | TEXT? | free text |
| `created_at`, `modified_at` | DATETIME | |

## `vaccine_records`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | primary key |
| `baby_id` | TEXT | → `babies.id` |
| `vaccine_name` | TEXT | free text |
| `dose_number` | INT? | |
| `scheduled_date` | DATETIME? | |
| `administered_date` | DATETIME? | null ⇒ scheduled/not yet given |
| `provider` | TEXT? | |
| `notes` | TEXT? | free text |
| `created_at`, `modified_at` | DATETIME | |

## Indices

Backing the hot per-baby, time-ordered query every tracker runs:

| Index | Table (columns) |
|---|---|
| `idx_feeding_baby_start` | `feeding_logs (baby_id, start_time)` |
| `idx_sleep_baby_start` | `sleep_logs (baby_id, start_time)` |
| `idx_diaper_baby_time` | `diaper_logs (baby_id, time)` |
| `idx_growth_baby_measured` | `growth_records (baby_id, measured_at)` |
| `idx_medicine_baby_administered` | `medicine_logs (baby_id, administered_at)` |
| `idx_vaccine_baby_administered` | `vaccine_records (baby_id, administered_date)` |

## Migration history

| To version | Change |
|---|---|
| 1 | Base schema: `babies`, `feeding_logs`, `sleep_logs`, `diaper_logs` |
| 2 | Add `growth_records` |
| 3 | Add `medicine_logs`, `vaccine_records` |
| 4 | Enforce foreign keys; clean rows orphaned before enforcement; collapse any multiple-active-baby state to one; (re)create indices |

`beforeOpen` enables `PRAGMA foreign_keys = ON` on every connection (SQLite
defaults it OFF and per-connection). Regenerate `*.g.dart` with `build_runner`
after any change here (see [../how-to/build-and-run.md](../how-to/build-and-run.md)).
