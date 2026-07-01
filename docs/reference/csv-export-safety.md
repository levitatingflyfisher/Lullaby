# Reference: CSV export safety

Precise rules for how Lullaby writes CSV cells so the exported medical record is
safe to open in a spreadsheet. Rationale: [ADR-0005](../adr/0005-csv-injection-safety.md).
Implementation: `_csvCell` in
[`lib/features/export/export_service.dart`](../../lib/features/export/export_service.dart).

> This document is precise about *intent and current behavior*. The code was
> AI-authored; the export tests are the check on it. If they disagree, the tests
> win.

## The invariant

**Every cell written to any exported CSV passes through `_csvCell`.** No cell is
produced by raw string interpolation. Both generators — the daily-summary CSV and
the raw event CSV — route every field through it. Header rows are static literals
and are safe by construction.

## The two rules, applied in order

Given a cell string `s`:

### 1. Formula-injection neutralization

If `s` is non-empty **and its first character** is one of:

```
=   +   -   @   \t (TAB, 0x09)   \r (CR, 0x0D)
```

then prepend a single apostrophe: `s → "'" + s`.

Spreadsheet apps interpret a cell beginning with any of these as a **formula**; a
leading apostrophe forces literal-text interpretation. This disarms values like a
crafted medicine name `=HYPERLINK(...)` without altering what the human reads as
content.

### 2. RFC-4180 quoting

If (after step 1) `s` contains a **comma**, a **double-quote**, or a **newline
(`\n`)**, then wrap the whole cell in double-quotes and **double every internal
double-quote**:

```
s → "\"" + s.replaceAll("\"", "\"\"") + "\""
```

Otherwise `s` is written unchanged.

## Worked examples

| Input cell | Output cell | Which rule(s) |
|---|---|---|
| `breast` | `breast` | none |
| `=SUM(A1:A9)` | `'=SUM(A1:A9)` | 1 (formula) |
| `-5` | `'-5` | 1 (leading `-` — see quirk below) |
| `@cmd` | `'@cmd` | 1 |
| `Tylenol, infant` | `"Tylenol, infant"` | 2 (comma) |
| `she said "fine"` | `"she said ""fine"""` | 2 (quote) |
| `=HYPERLINK("http://x","c")` | `"'=HYPERLINK(""http://x"",""c"")"` | 1 then 2 |
| `` (empty) | `` (empty) | none |

## Free-text attack surface

The columns that carry parent-typed free text — and therefore the ones this
protects — are principally the **medicine name** and **vaccine name** (and any
concatenated `details`/`type` field). These are exactly the values an attacker (or
an accident) could shape into a formula, which is why they must never bypass
`_csvCell`.

## Notes & known quirks

- **Order matters.** Neutralization runs *before* quoting. A leading apostrophe is
  not a quoting trigger, so a neutralized-but-otherwise-plain cell stays unquoted.
- **Cosmetic cost.** A cell that legitimately begins with `-` or `=` (rare in this
  data) gains a leading apostrophe when opened. Accepted trade for safety
  ([ADR-0005](../adr/0005-csv-injection-safety.md)).
- **Trigger set is exactly** `= + - @ \t \r`. A leading `\n` is not a
  neutralization trigger, but any embedded newline forces RFC-4180 quoting via
  rule 2.
- **Extending the export:** a new CSV column is a new free-text surface. Route it
  through `_csvCell` and add a test; a raw-interpolated cell is a regression.
