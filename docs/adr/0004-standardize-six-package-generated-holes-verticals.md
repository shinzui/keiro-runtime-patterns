# ADR 0004: Standardize six-package Generated/Holes verticals

## Status

Accepted — 2026-07-22

## Context

The service fleet needs one structure that keeps generated contracts replaceable, domain decisions hand-owned, and deployable roles independently buildable. Danwa's shipped code uses six cabal packages and collocates a keiro-dsl `Generated.*` ring with one create-once `Holes` module per aggregate. Older danwa prose describes an abandoned flat layout, while keiro-runtime-jitsurei intentionally retains duplicate hand modules inside a teaching monolith.

## Decision

Use exactly six packages for a deployed keiro service: `<service>-core`, `-api`, `-server`, `-workers`, `-migrations`, and `-client`. Colocate all code for a domain concept under `<Service>.<Concept>.*` across those packages.

Within core, keiro-dsl owns `<Concept>.Generated.*` and a developer owns one `<Concept>.Holes` module plus the hand-written read model. Reject the earlier flat generated layout and reject parallel hand-written `Transducer`, `Projection`, `EventStream`, or `CommandProcessor` modules that duplicate the generated ring. A one-package service remains acceptable only for explicitly labeled teaching and example repositories.

## Consequences

- Re-scaffolding may replace generated structure without overwriting domain decisions.
- Core, API, server, workers, migrations, and client retain separate dependency budgets.
- A concept remains navigable across packages, while the closed cross-cutting allowlist prevents technical-layer sprawl.
- The service blueprint must emit this structure and must not copy the legacy alternatives from either reference repository.

## Alternatives Considered

**Flat generated modules with separate hand transducer/projection modules.** Rejected because danwa abandoned it and it weakens the generated-code firewall.

**One cabal package per deployed service.** Rejected because it erases deployable-role and dependency boundaries; retained only for teaching repositories such as keiro-runtime-jitsurei.

**Additional packages for each technology.** Rejected because integration and persistence behavior belongs either to a domain vertical or to the closed cross-cutting allowlist.

## Related Guidance

- [Vertical-slice modules](../../architecture/vertical-slice-modules.md)
- [Service packages](../../architecture/service-packages.md)
- [Specification and scaffolding](../../architecture/spec-and-scaffolding.md)
- [ADR 0002: adopt keiro-dsl](0002-adopt-keiro-dsl-for-contracts-and-evolution.md)
