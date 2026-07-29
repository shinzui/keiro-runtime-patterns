---
type: Overview
title: "Keiro runtime patterns"
description: "Index of prescriptive Keiro runtime and DSL standards; start here"
timestamp: 2026-07-29T12:40:01-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-overview
tags: [keiro, overview]
status: current
---

# Keiro runtime patterns

**Prescriptive defaults for assembling reliable services on the current Keiro 0.4 source line and Keiki 0.4.**

Use this area as the fleet standard for application wiring and operating boundaries; use the Keiro repo's `docs/user/README.md` as the long-form API reference. The 0.2 and 0.3 behavior remains foundational, while the current 0.4 source line adds composable multi-file service workspaces, structural consumer mappings, generated migration evidence, replay-impact targeting, and the Keiki 0.4 field-projection contract.

Keiki 0.4.0.0 is published and tagged. As of 2026-07-28, Hackage and upstream Keiro tags still expose 0.3.0.0 even though the local 0.4 source and changelogs contain the documented surface. Verify the registry and upstream tags before choosing package bounds; do not claim the structural mapping workflow from a 0.3-only dependency set.

The 0.4 line also changes three runtime surfaces incompatibly: `scheduleTimerOnceTx` returns `Bool`, `markChildFailedTx` takes a failure reason, and `StateCodec` gains `stateShapeHash`. Migrations `0019` and `0020` accompany the last two, and snapshot-enabled code requires Keiki 0.4.

## Start here

Read runtime assembly first, the schema arrangement second, and the DSL adoption decision before writing a new service.

- [Runtime assembly](runtime-assembly.md) — acquire resources, validate event streams, and configure options.
- [Two-schema arrangement](two-schema-arrangement.md) — keep the kiroku store, keiro framework, and application schemas distinct.
- [Keiro-dsl adoption](dsl-adoption.md) — decide when checked specifications and the evolution gate pay off.
- [Composable service workspaces](service-workspaces.md) — split complete aggregates across single-owner members while keeping one atomic scaffold and evolution boundary.
- [Brownfield Keiro adoption](brownfield-adoption.md) — keep existing types and historical wire values while moving to one generated codec authority and a replay-audited cutover.
- [Command cycle and errors](command-cycle-and-errors.md) — classify command failures and reject ambiguity as a definition bug.
- [Read models and projections](read-models-and-projections.md) — register consistency contracts, honor async fences, and rebuild safely.
- [Durable workflows](durable-workflows.md) — journal side effects and deploy the progress mechanisms each workflow uses.
- [Workflow reliability and recovery](workflow-reliability.md) — size leases, budget failures, and resurrect terminal instances.
- [Evolution gates and rollout ordering](evolution-and-rollout.md) — pass every gate before deploying a change to a service that holds data.
- [Telemetry](telemetry.md) — connect tracing, metrics, propagation, and application logging hooks.
- [Gotchas](gotchas.md) — avoid shared-stream, global-lock, resource-effect, silent-failure, and Kafka integration traps.

## Related Patterns

- [Kiroku event-store patterns](../kiroku/overview.md)
- [Keiki transducer patterns](../keiki/overview.md)
- [Typed field projections](../keiki/typed-field-projections.md)
