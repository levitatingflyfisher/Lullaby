# Architecture Decision Records

An ADR captures **one architectural decision**: the context that forced it, the
choice made, and the consequences we accepted. They are immutable once accepted —
if a decision is revisited, add a *new* ADR that supersedes the old one (and mark
the old one `Superseded by ADR-NNNN`) rather than editing history.

Read these when you're about to change something load-bearing and want to know
whether you're fixing a mistake or unknowingly reopening a settled trade-off.

## Index

| # | Decision | Status |
|---|---|---|
| [0001](0001-local-first-no-account.md) | Local-first, on-device only, no account or BaaS | Accepted |
| [0002](0002-clean-architecture.md) | Clean Architecture with feature-first modules | Accepted |
| [0003](0003-drift-over-sqflite.md) | Drift (typed SQLite) over sqflite | Accepted |
| [0004](0004-encrypted-backup-seed-phrase.md) | Encrypted backup via a seed phrase; crypto lives out-of-repo | Accepted |
| [0005](0005-csv-injection-safety.md) | Neutralize spreadsheet formula injection in the CSV export | Accepted |
| [0006](0006-native-and-web-drift-connection.md) | One schema, native + web, via a conditional Drift connection | Accepted |

## Writing a new one

Copy [`0000-template.md`](0000-template.md) to the next number, fill it in, add a
row above. Keep it to ~one screen — an ADR that needs scrolling is two ADRs.
