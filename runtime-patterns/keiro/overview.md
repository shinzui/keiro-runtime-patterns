---
type: Overview
title: "Keiro runtime patterns"
description: "Index of prescriptive Keiro runtime and DSL standards; start here"
timestamp: 2026-07-31T16:04:17-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-overview
tags: [keiro, overview]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T12:40:01-07:00
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; changes requested: the Hackage-still-at-0.3.0.0 caveat is stale; 0.4.0.1 is published.
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T01:11:55Z
    document_timestamp: 2026-07-29T18:11:55-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction against Hackage and the keiro tags: release availability now states 0.4.0.1/0.4.0.0 and scopes workspaces to the post-0.4.0.1 source line.
---

# Keiro runtime patterns

**Prescriptive defaults for assembling reliable services on the released Keiro 0.6.0.0 set and Keiki 0.6.**

Use this area as the fleet standard for application wiring and operating boundaries; use the Keiro repo's `docs/user/README.md` as the long-form API reference. The 0.2 through 0.4 behavior remains foundational, while 0.5 and 0.6 add composable multi-file service workspaces, an explicit DSL language-version contract, consumer-owned nominal bindings, and authoritative typed scalar aggregate expressions.

Keiro 0.6.0.0 is the current release. All five packages — `keiro`, `keiro-core`, `keiro-dsl`, `keiro-pgmq`, and `keiro-migrations` — move together and are tagged upstream as one set; mixed versions across that set are unsupported. Upgrade the whole set at once and verify the registry and upstream tags before choosing bounds.

Two cycles arrived in quick succession. 0.5.0.0 was entirely `keiro-dsl`: composable service workspaces, now released rather than checkout-only. 0.6.0.0 is dominated by `keiro-dsl` again — the source-language contract, nominal bindings, and scalar aggregate expressions — while `keiro-core` gains the public `Keiro.Codec.Nominal` binding and fixture API (re-exported from `keiro`, so generated consumers keep one direct dependency) and both move to `keiki >=0.6 && <0.7`. `keiro` and `keiro-pgmq` take `keiro-core ^>=0.6.0.0`. Beyond those bounds and the new codec surface, the runtime packages carry no behavior change from 0.4.0.1.

The 0.4 line changed three runtime surfaces incompatibly and those rules still apply: `scheduleTimerOnceTx` returns `Bool`, `markChildFailedTx` takes a failure reason, and `StateCodec` gains `stateShapeHash`.

Migrations `0019` and `0020` accompany the last two of those, and snapshot-enabled code requires Keiki 0.4 or later.

## Start here

Read runtime assembly first, the schema arrangement second, and the DSL adoption decision before writing a new service.

- [Runtime assembly](runtime-assembly.md) — acquire resources, validate event streams, and configure options.
- [Two-schema arrangement](two-schema-arrangement.md) — keep the kiroku store, keiro framework, and application schemas distinct.
- [Keiro-dsl adoption](dsl-adoption.md) — decide when checked specifications and the evolution gate pay off.
- [Keiro DSL language versions](language-versions.md) — declare the source language, choose between version 1 and version 2, and audit legacy sources.
- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md) — declare guards and writes that generate the transducer, and mark what stays hand-owned.
- [Consumer-owned nominal bindings](nominal-bindings.md) — keep existing ID, enum, and scalar-wrapper types in checked aggregate fields.
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
