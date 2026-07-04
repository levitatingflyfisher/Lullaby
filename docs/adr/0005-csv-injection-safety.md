# ADR-0005: Neutralize spreadsheet formula injection in the CSV export

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision made in commit `c2d7eba`)

## Context

Lullaby exports a medical CSV (feeds, sleep, diapers, growth, medicines,
vaccines) that a parent will hand to a paediatrician or open in Excel / Google
Sheets / Numbers. Several columns are **free text the parent typed** — a medicine
name, a note. Spreadsheet software treats a cell that begins with `=`, `+`, `-`,
`@`, or a tab/carriage-return as a **formula**. So a medicine named
`=HYPERLINK("http://evil","click")` — or a value crafted by someone with brief
access to the phone — could execute when the exported file is opened. This is CSV
/ formula injection (OWASP), and it is exactly the wrong surprise in a document
about a baby's health.

## Decision

Every cell written to an exported CSV passes through a single sanitizer
(`_csvCell` in `export_service.dart`) that does two things, in order:

1. **Neutralize formula triggers.** If the cell's first character is one of
   `= + - @ \t \r`, prefix the cell with a single apostrophe (`'`) so the
   spreadsheet treats it as literal text, not a formula.
2. **RFC-4180 quote.** If the cell contains a comma, double-quote, or newline,
   wrap it in double-quotes and double any internal quotes.

No CSV cell is ever written by string interpolation that bypasses `_csvCell`.

See [reference/csv-export-safety.md](../reference/csv-export-safety.md) for the
exact rules and examples.

## Consequences

- **Buys:** the exported medical record is safe to open anywhere; a hostile or
  accidental formula-shaped value renders as text. A single choke-point that is
  easy to test and audit.
- **Costs:** a cell that legitimately begins with `-` (rare here) or `=` gains a
  leading apostrophe on open — a cosmetic quirk accepted in exchange for safety.
- **Forecloses:** ad-hoc CSV building. Any new export column must route through
  `_csvCell`; a raw-interpolated cell is a review-time reject and a regression.

## Alternatives considered

- **Trust the data (no sanitization):** rejected — free-text medical fields are
  attacker/accident-controlled and the output is opened in a formula engine.
- **Strip/deny special characters:** rejected — it silently corrupts legitimate
  content; apostrophe-prefixing preserves the value while disarming it.
