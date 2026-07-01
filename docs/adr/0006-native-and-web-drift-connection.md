# ADR-0006: One schema, native + web, via a conditional Drift connection

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision made when web support was added)

## Context

Lullaby targets Android, iOS, and Linux (native) and is also built for the web.
Native platforms open SQLite through `sqlite3_flutter_libs` and a file on disk;
the browser has no filesystem SQLite and must run SQLite compiled to WebAssembly
(`sqlite3.wasm`) against browser storage. We want **one schema and one set of
DAOs** — writing the persistence layer twice, or littering it with
`if (kIsWeb)`, would guarantee drift between platforms.

## Decision

Isolate the platform difference behind a **conditional import** in
`lib/services/database/connection/`:

- `connection.dart` conditionally imports `native.dart` (when `dart:io` is
  available) or `web.dart` (when `dart:html` is available) and exposes one
  `openConnection()`.
- `native.dart` opens a `NativeDatabase` on a file under the app documents dir.
- `web.dart` opens a `WasmDatabase` backed by `sqlite3.wasm`.

`AppDatabase` calls `openConnection()` and is otherwise platform-agnostic. The
web build must ship `sqlite3.wasm` and the Drift worker as web assets.

## Consequences

- **Buys:** a single schema, single migration path, and single DAO set across all
  platforms; the same code runs in tests, on device, and in the browser.
- **Costs:** the web target carries extra assets (`sqlite3.wasm`) and its own
  boot/storage-persistence considerations; the conditional-import indirection is
  slightly less obvious than a direct import.
- **Forecloses:** platform-specific storage forks. A platform difference belongs
  behind `openConnection()`, not sprinkled through the app.

## Alternatives considered

- **`if (kIsWeb)` branches in app code:** rejected — leaks a platform concern into
  every call site and rots.
- **A different store on web (e.g. IndexedDB via a separate ORM):** rejected —
  two schemas to keep in sync is exactly the failure we're avoiding.
