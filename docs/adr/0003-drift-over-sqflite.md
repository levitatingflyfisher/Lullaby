# ADR-0003: Drift (typed SQLite) over sqflite

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision load-bearing since v1.0.0)

## Context

The app needs a local relational store with related tables (a baby has many
feeds, sleeps, diapers, …), time-ordered queries, migrations across releases, and
— critically — the ability to run the exact same storage logic in fast, isolated
tests. The Flutter options are the low-level `sqflite` (raw SQL strings, untyped
`Map<String, dynamic>` rows, hand-written mapping) and `drift` (a typed,
code-generated ORM over SQLite).

## Decision

Use **Drift**. Tables are declared in Dart (`tables.dart`); Drift generates typed
row classes, companions, and DAOs (`*.g.dart`). Queries live in DAOs and return
typed rows and reactive `Stream`s. Tests use Drift's `NativeDatabase.memory()`
for a real SQLite engine with no device and no mocking.

## Consequences

- **Buys:** compile-time-checked columns and queries; reactive `watch…` streams
  that drive live UI updates for free; painless in-memory testing (the repository
  test suite runs against real SQLite); a first-class web target
  ([ADR-0006](0006-native-and-web-drift-connection.md)).
- **Costs:** a code-generation step (`build_runner`) that must be re-run after any
  schema change, and committed `*.g.dart` files. A learning curve over raw SQL.
- **Forecloses:** hand-rolled SQL string mapping. New tables/queries go through
  Drift codegen; generated files are never hand-edited.

## Alternatives considered

- **sqflite (raw):** rejected — untyped rows and hand-written mapping are
  error-prone for a medical record, and it has no reactive streams and a weaker
  web story.
- **A key-value / NoSQL store (Hive, Isar):** rejected — the data is inherently
  relational (foreign keys, joins, time-range aggregation for stats) and benefits
  from SQL and enforced foreign keys.
