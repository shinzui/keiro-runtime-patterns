# ADR 0007: Scope runtime standards to Kiroku, not Kioku

## Status

Accepted — 2026-07-22

## Context

Kiroku and Kioku are separate libraries with similar names. Kiroku is the PostgreSQL event store underneath Keiro services. Kioku is an agent-memory library. Treating them as interchangeable would mix unrelated persistence models and make the runtime corpus appear to govern APIs it never reviewed.

The fleet initiative needs standards for the event store used by every Keiro service. Some existing consumer repositories may independently use Kioku, so a general migration tool can still need to preserve or migrate that component.

## Decision

The Keiro runtime standards cover Kiroku and exclude Kioku. References to the foundational event store must use the name Kiroku and its released package family.

This documentation scope does not remove Kioku support from tools that operate on arbitrary applications. In particular, `migrate-keiro-stack` may retain an optional Kioku migration phase when the target application actually depends on it; that phase is not evidence that Kioku belongs to the runtime standard.

## Consequences

- Event-store guidance, migration ordering, and telemetry stay grounded in Kiroku's source and release contracts.
- No Kioku API or operational claim enters this corpus without a separate scoped initiative.
- Migration blueprints must distinguish package discovery from the standards' runtime dependency set.
- Future requests using either name should resolve the intended library before changing dependency or documentation scope.

## Alternatives Considered

**Document both libraries as one runtime concern.** Rejected because agent memory and event sourcing have different consumers, APIs, and operational guarantees.

**Remove every Kioku mention from migration tooling.** Rejected because the migration blueprint targets arbitrary existing services and must not discard a real dependency merely because it is outside this corpus.

## Related Guidance

- [Keiro runtime standards MasterPlan](../masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md)
- [Kiroku event-store patterns](../../kiroku/README.md)
- [Seihou blueprint refresh](../plans/9-refresh-the-seihou-blueprints-to-encode-the-standards.md)
