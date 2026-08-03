---
type: Overview
title: "Keiro runtime patterns"
description: "Index of prescriptive Keiro runtime and DSL standards; start here"
timestamp: 2026-08-02T19:56:33-07:00
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

**Prescriptive defaults for assembling reliable services on the released Keiro 0.8.0.0 set and Keiki 0.7.**

Use this area as the fleet standard for application wiring and operating boundaries; use the Keiro repo's `docs/user/README.md` as the long-form API reference. The 0.2 through 0.4 behavior remains foundational, while 0.5 through 0.8 add composable multi-file service workspaces, an explicit DSL language-version contract, consumer-owned nominal bindings, authoritative typed scalar aggregate expressions, an enforced identifier domain, and complete aggregate behavior conformance.

Keiro 0.8.0.0 is the current release. All five packages — `keiro`, `keiro-core`, `keiro-dsl`, `keiro-pgmq`, and `keiro-migrations` — move together and are tagged upstream as one set; mixed versions across that set are unsupported. Upgrade the whole set at once and verify the registry and upstream tags before choosing bounds.

Four cycles arrived in quick succession, and every one of them is dominated by `keiro-dsl`:

- **0.5.0.0** released composable service workspaces.
- **0.6.0.0** added the source-language contract, nominal bindings, and scalar aggregate expressions; `keiro-core` gained the public `Keiro.Codec.Nominal` binding and fixture API.
- **0.7.0.0** added [language version 3](language-versions.md) with the enforced [TypeID-v7 identifier domain](identifier-domains.md), one deterministic `Generated.<Context>.Nominals` owner for every service-level ID and enum, the `CheckedService`/`EffectiveLanguageContract` semantic boundary, and complete [behavior conformance](behavior-conformance.md). `keiro-core` gained the public `Keiro.Codec.IdDomain` contract, re-exported from `keiro`.
- **0.8.0.0** is a `keiro-dsl`-only cycle: the grammar moved behind the stable `Keiro.Dsl.Parser` facade, the located `Keiro.Dsl.Source`/`Syntax`/`Frontend` API was published, and every registry entry now selects its syntax profile and runtime-semantics identity explicitly instead of inheriting them from numeric version ordering. `keiro-core`, `keiro`, `keiro-pgmq`, and `keiro-migrations` are unchanged and move with the set.

The whole set requires `keiki >=0.7 && <0.8`. That bound carries a behavioral consequence: Keiki 0.7 classifies a predicate crossing a one-way generated projection conservatively, so symbolic verification may report `UnverifiedOpaque` where an earlier release reported a verified result. Command execution and replay are unchanged, and conformance tooling must preserve the unverified classification rather than relabel it. Beyond the bounds and the two new `keiro-core` codec surfaces, the runtime packages carry no behavior change from 0.4.0.1.

The 0.4 line changed three runtime surfaces incompatibly and those rules still apply: `scheduleTimerOnceTx` returns `Bool`, `markChildFailedTx` takes a failure reason, and `StateCodec` gains `stateShapeHash`.

Migrations `0019` and `0020` accompany the last two of those, and snapshot-enabled code requires Keiki 0.4 or later.

## Start here

Read runtime assembly first, the schema arrangement second, and the DSL adoption decision before writing a new service.

- [Runtime assembly](runtime-assembly.md) — acquire resources, validate event streams, and configure options.
- [Two-schema arrangement](two-schema-arrangement.md) — keep the kiroku store, keiro framework, and application schemas distinct.
- [Keiro-dsl adoption](dsl-adoption.md) — decide when checked specifications and the evolution gate pay off.
- [Keiro DSL language versions](language-versions.md) — declare the source language, choose among versions 1 through 3, and carry the checked contract through tooling.
- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md) — declare guards and writes that generate the transducer, and mark what stays hand-owned.
- [Consumer-owned nominal bindings](nominal-bindings.md) — keep existing ID, enum, and scalar-wrapper types in checked aggregate fields.
- [Enforced identifier domains](identifier-domains.md) — put prefix-bearing IDs on the frozen TypeID-v7 contract and roll the adoption out producer-last.
- [Behavior conformance and obligations](behavior-conformance.md) — inventory every transition, rejection, and replay-only edge, and prove each with an executed witness.
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
- [Exact projection domains](../keiki/exact-projection-domains.md)
