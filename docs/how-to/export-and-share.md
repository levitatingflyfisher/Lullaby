# How to export, share & back up

Lullaby has two distinct "get my data out" flows with different purposes and
different privacy properties. Know which one you want.

| I want to… | Use | Result |
|---|---|---|
| Give my paediatrician a readable summary | **Export (PDF/CSV)** | A **plaintext** file, shared via the OS share sheet |
| Protect my data against losing the phone / move to a new phone | **Encrypted backup** | An **encrypted `.ohbk`** file only I can decrypt |

See [../privacy-model.md](../privacy-model.md) for the full privacy implications.

## Export a doctor summary or raw data (plaintext)

From the export sheet you can produce:

- **A doctor-summary PDF** — recent averages, latest growth with WHO percentiles,
  recent medicines, and administered vaccines, rendered for an appointment.
- **A summary CSV** — one row per day (feed count/minutes, sleep minutes, diaper
  counts by type).
- **A raw CSV** — one row per event across all record types, chronologically.

All CSV output is passed through the formula-injection-safe cell writer, so it is
safe to open in Excel / Google Sheets / Numbers — see
[../reference/csv-export-safety.md](../reference/csv-export-safety.md). Files are
handed to the OS **share sheet** (`share_plus`); where they go next is your
choice.

> **These exports are plaintext.** A CSV/PDF is only as private as wherever you
> send it. For safekeeping (not sharing), use the encrypted backup instead.

## Set up an encrypted backup

The encrypted backup is protected by a **12-word recovery seed phrase** — a key
you hold. There is no account and no password reset.

1. **Generate a seed phrase.** The app creates a random 12-word phrase and shows
   it once.
2. **Write it down and store it somewhere safe** (offline). This phrase is the
   *only* way to decrypt your backups.
3. **Confirm it.** You re-enter the phrase; the app verifies it cryptographically
   (a wrong re-entry is rejected), turning "I clicked *got it*" into "I can
   reproduce the key."

> **If you lose the seed phrase, your encrypted backups cannot be recovered.**
> That is the deliberate trade for holding your own keys.

## Create and restore a backup

**Export a backup:**
- The app serializes all records, encrypts them under your seed-derived key, and
  produces a file named `lullaby-backup-YYYY-MM-DD.ohbk`. Save it wherever you
  keep safe files. Nothing is uploaded anywhere by the app.

**Restore a backup:**
- Pick an `.ohbk` file and provide the seed phrase. The app decrypts it and
  **replaces all current data** with the backup's contents.

> **Restore is destructive.** It wipes existing data and inserts the backup's, in
> a single transaction (all-or-nothing). The UI reports a specific outcome — wrong
> phrase, corrupt file, or a backup made by a *newer* app version (which is
> refused rather than partially applied). Restoring onto a device that already has
> data will overwrite it.

## Move to a new phone

1. On the old phone: set up a seed phrase (if you haven't) and **export a backup**.
2. Transfer the `.ohbk` file to the new phone.
3. On the new phone: install Lullaby, enter the **same seed phrase**, and
   **restore** the backup.
