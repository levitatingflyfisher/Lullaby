# ADR-0007: Two-phone sync through hearthSync: what syncs, and how it merges

- **Status:** Accepted
- **Date:** 2026-10-02

## Context

Two parents share one baby's nights. Until now the only way to share the record
was one phone, or an encrypted backup carried between phones (VISION, Horizons:
"how do two parents share one baby's record without a server?"). The fleet's
answer is the shared sync kernel, `hearth_sync` (`../hearthSync`, ADRs
0008–0013 there): a signed, hash-linked operation log, sealed with keys from the
household's 12 words and carried by a dumb relay the household chooses. Lullaby
is its first adopter. The kernel fixes the merge rules; each app must say which
of its data is in the log, under which names and types, for good (hearthSync
ADR 0009: a declared name never changes kind or type and is never removed).

## Decision

**Sync is off until a parent turns it on.** With no relay chosen, the kernel is
not even loaded and the app makes no network call. Turning it on (Settings →
Sync with another phone) needs the 12 recovery words: the same words on every
phone are the household (fleet sync decision 2; every phone stores them). A
second phone joins by typing the same words.

**What syncs** (app `lullaby`, horizon 90 days). Every record table is a
last-writer-wins table, per field, so two parents editing different fields of
one feed both keep their edit. An edit beats a concurrent delete; Undo is the
kernel's Restore, so it never expires and reaches the other phone.

| Collection | Kind | Fields |
|---|---|---|
| `babies` | table | name, date_of_birth, gender, created_at, modified_at |
| `feeding_logs` | table, container `baby_id` → `babies` | baby_id, type, start_time, end_time, duration_minutes, side, amount_ml, amount_oz, notes, created_at, modified_at |
| `sleep_logs` | same container | baby_id, start_time, end_time, duration_minutes, type, location, notes, created_at, modified_at |
| `diaper_logs` | same | baby_id, time, type, color, notes, created_at, modified_at |
| `growth_records` | same | baby_id, measured_at, weight_kg, height_cm, head_circumference_cm, notes, created_at, modified_at |
| `medicine_logs` | same | baby_id, medicine_name, dosage, dosage_unit, administered_at, notes, created_at, modified_at |
| `vaccine_records` | same | baby_id, vaccine_name, dose_number, scheduled_date, administered_date, provider, notes, created_at, modified_at |
| `handoff_notes` | append-only stream of text | JSON `{baby, text, by, at}` |

Field names are the Drift column names. **Types, fixed for good:** text is
text; whole numbers are int; a date-time is an int of **Unix seconds** (what
Drift stores, so a stored row and its log entry always compare equal); a real
number (ml, oz, kg, cm, dose) is **text**, Dart's shortest round-trip form of
the double, because the kernel has no float type. Every field is nullable, so
a write can clear one.

**Containers.** Every record names its baby as its container, so deleting a
baby hides all of its records on every phone, and Undo brings them back.
Handoff notes are a stream, which has no container: a note whose baby is
deleted stays in the log and is simply not shown.

**Handoff notes are new.** "Night handoff notes" were named in the workshop's
map, not in VISION; until now a record's notes field was the only shared
scratch space. A handoff note is a short line for whoever takes the next shift
("last feed 3:10, left side; she's fussy"), signed by the phone that wrote it.
Append-only, as the kernel design sets out for logs: a correction is a new note.

**Device-local, never synced:** which baby is selected (`babies.is_active`),
the baby's photo (`photo_path` is a file on this phone; photos do not sync),
the theme, the relay choice, this phone's name, the Finish-setup reminder, and
the backup vault.

**Writes.** Repositories write through one `RecordWriter`. With sync off it
writes Drift directly; with sync on it writes through `HearthSync`, and Drift
is filled only from the kernel's changes, in the same transaction as the
kernel's records (`DriftPersist.applyTables`). An update sends only the fields
that changed, so it never stamps a field the parent did not touch. Turning sync
on, or reopening it, first puts every local row the log does not yet hold.

**Writes while the words are missing.** Sync can be on while the log cannot be
opened, because the words left the phone (the secure store was cleared). Writes
then go to Drift directly, and the reopen's put-import carries them into the
log. A put cannot carry a delete, so a delete made in that gap is remembered in
`sync_gap_deletes` (an Undo in the gap clears it) and replayed as a log delete
before the put-import. Without that the deleted record lived on in the household
and came back. Turning sync off clears the list, so a later join cannot replay
deletes into another log.

## Consequences

- **Buys:** both parents see every feed, nap and note; concurrent edits to
  different fields both survive; deletes and Undo travel; a lost phone is
  removed with "Forget this device" (phrase-protected).
- **Costs:** the app now has a network path (`INTERNET` on Android) and the
  `http` client, used only when a parent chose a relay, and a same-Wi-Fi
  listener and client (hearthSync ADR 0014), used only while a parent shows or
  types a code (Android only; a web page cannot listen). Data leaves the phone
  sealed (XChaCha20-Poly1305 under keys from the words); the relay sees sizes,
  timing, device keys and each phone's name (in plain text), never content. Restoring a backup while sync is on
  is refused for now: a restore cannot be one transaction through the log.
- **Forecloses:** renaming or retyping any field above. A new field is a new
  name.

## Alternatives considered

- **Kernel always on, from first launch:** needs a household seed before the
  parent has seen any words; first run must open into the task (ruling 48).
- **Row-level last-writer-wins:** loses the other parent's edit to a
  different field of the same record.
- **Reals as integer milli-units:** dose units vary (ml, mg, drops); text keeps
  the exact double with no unit assumption.
