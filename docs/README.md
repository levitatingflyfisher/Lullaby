# Documentation

Organized on the [Diátaxis](https://diataxis.fr/) model — four kinds of docs for
four different needs. Find what you need by *what you're trying to do*, not by
guessing a filename.

| I want to… | I need | Go to |
|---|---|---|
| **learn by doing** | a Tutorial | [Tutorials](#tutorials) |
| **accomplish a specific task** | a How-to guide | [How-to guides](#how-to-guides) |
| **look up exact details** | Reference | [Reference](#reference) |
| **understand why** | Explanation | [Explanation](#explanation) |

New here? Start with the [README](../README.md) and the [Vision](../VISION.md),
then read [Explanation § Concepts](concepts.md).

---

## Tutorials
*Learning-oriented — take me by the hand through my first success.*

- The **[README § Getting Started](../README.md#getting-started)** — clone, `flutter
  pub get`, and run the app.

*Gap (contributions welcome):* a hand-held "log your first feed, sleep, and
diaper, then read the doctor summary in 5 minutes" tutorial. If you write one,
put it in `docs/tutorials/`.

## How-to guides
*Task-oriented — how do I accomplish X (assumes you know the basics)?*

- **[Build & run](how-to/build-and-run.md)** — set up the toolchain and run on
  Android / iOS / Linux / web, including the Drift code-generation step.
- **[Export, share & back up](how-to/export-and-share.md)** — export a doctor
  summary (PDF/CSV) and create or restore an encrypted backup.
- Working *in* this repo (agents & contributors): **[AGENTS.md](../AGENTS.md)**
  and **[CONTRIBUTING.md](../CONTRIBUTING.md)**.

## Reference
*Information-oriented — tell me exactly, precisely, completely.*

- **[Data model](reference/data-model.md)** — every table, column, relationship,
  index, and the migration history.
- **[Feature status](reference/feature-status.md)** — what's shipped vs. partial,
  per area.
- **[CSV export safety](reference/csv-export-safety.md)** — the exact cell-quoting
  and formula-injection-neutralization rules for the medical CSV.
- **[Backup file format (OHBK)](reference/backup-format.md)** — the encrypted
  backup blob's byte layout and the crypto trust boundary.

## Explanation
*Understanding-oriented — help me understand the ideas and the why.*

- **[Vision](../VISION.md)** — the one idea, the design commitments, the honest scorecard.
- **[Architecture overview](architecture/OVERVIEW.md)** — the layers + diagrams.
- **[Architecture Decision Records](adr/)** — why each load-bearing choice was made.
- **[Concepts](concepts.md)** — the domain model, the Clean-Architecture layering,
  local-first data flow.
- **[Privacy model](privacy-model.md)** — what leaves the device, when, and how to
  verify it.
- **[Limitations](limitations.md)** — read before adopting. What it does *not* do.

---

### The white paper

- **[White paper](whitepaper.md)** — the conceptual case: why a *local-first* baby
  tracker matters, who it's for, and how it differs from the cloud incumbents.

*(There is no "yellow paper" / formal spec: this is a Flutter app, not an
algorithmic engine. The two places precision genuinely matters — the CSV export
rules and the backup wire format — are written up under [Reference](#reference)
instead.)*
