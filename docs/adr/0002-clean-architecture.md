# ADR-0002: Clean Architecture with feature-first modules

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision load-bearing since v1.0.0)

## Context

Lullaby has many small, similar features (feeding, sleep, diaper, growth,
medicine, vaccine, …), each with a screen, some state, and a bit of persistence.
Two failure modes are easy to fall into: a "big ball of mud" where UI code calls
the database directly, and a layer-first layout (`screens/`, `models/`,
`repositories/`) that scatters one feature across the whole tree. Both make a
feature hard to reason about, hard to test, and hard to delete.

## Decision

Organize the codebase **feature-first**, and split each feature into the three
Clean Architecture layers with dependencies pointing **inward**:

```
lib/features/<feature>/
  domain/        # entities (plain Dart, Equatable) + abstract repository interface
  data/          # repository implementation backed by a Drift DAO; maps rows ↔ entities
  presentation/  # Flutter screens/widgets + Riverpod controllers
```

The `presentation` layer depends only on the `domain` interface — it never
imports Drift. The `data` layer implements the `domain` interface. Shared
cross-cutting code lives in `lib/core/`; the database engine lives in
`lib/services/database/`.

## Consequences

- **Buys:** each feature is a self-contained, deletable unit. Controllers are
  testable against a fake/in-memory repository; repository impls are testable
  against an in-memory SQLite database. A storage change touches `data/` +
  `services/`, not the UI.
- **Costs:** boilerplate — every feature needs an entity, an interface, an impl,
  and a provider, even when it is thin. More files, more indirection.
- **Forecloses:** UI-reaches-into-the-database shortcuts. A new feature that skips
  the domain interface is a review-time reject.

## Alternatives considered

- **Layer-first folders** (`screens/`, `repositories/`, `models/`): rejected —
  spreads one feature across the tree and invites cross-feature coupling.
- **No repository layer (controllers call DAOs directly):** rejected — ties every
  controller and its tests to Drift, and leaks storage concerns into the UI.
