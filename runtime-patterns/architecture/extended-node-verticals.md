---
type: Pattern
title: "Extended Keiro-DSL Node Verticals"
description: "Where read models, process managers, workflows, routers, publishers, inboxes, queues, and contracts sit in the slice"
timestamp: 2026-09-18T13:41:24Z
generated:
  by: process:codex
  at: "2026-09-18T13:41:24Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-extended-node-verticals
tags: [architecture, extended-node-verticals]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T18:42:26Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved danwa and keiro-runtime-jitsurei reference applications and the keiro-dsl scaffolder at HEAD; verified exported symbols, signatures, version claims, and links.
  - kind: model
    reviewer: codex
    reviewed_at: 2026-09-18T13:31:31Z
    document_timestamp: 2026-09-18T13:01:11Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: openai
    model: gpt-6
    effort: unspecified
    context: >-
      Targeted generated-layout review against mori://shinzui/keiro at 9fb54d56db4f, project-relative keiro-dsl/src/Keiro/Dsl/Scaffold.hs (scaffoldReadModelForService, pascal/generatedCase) and HaskellName.hs (deriveHaskellName, segmentLogicalName); source artifact-level URIs pending. Current generation converts hospital_readiness to HospitalReadiness and reservation_work to ReservationWork; the prescribed underscore paths describe legacy example output. Typed read models additionally emit QueryContract.hs, omitted from the fixed three-generated-module inventory. Other sections were not exhaustively reverified.
  - kind: model
    reviewer: codex
    reviewed_at: 2026-09-18T13:41:24Z
    document_timestamp: 2026-09-18T13:41:24Z
    scope: technical-accuracy
    outcome: approved
    provider: openai
    model: gpt-6
    effort: unspecified
    context: >-
      Approved the targeted corrections to module naming and read-model inventory against mori://shinzui/keiro at 9fb54d56db4f: project-relative keiro-dsl/src/Keiro/Dsl/Scaffold.hs (scaffoldReadModelForService, pascal/generatedCase), HaskellName.hs (deriveHaskellName, segmentLogicalName), and Harness.hs (ReadModelHarness emission); source artifact-level URIs pending. UpperCamelCase segments and the conditional QueryContract module match current source. This approval covers those corrections, not an exhaustive re-review of other sections.
---

# Extended Keiro-DSL Node Verticals

**Every first-class DSL node gets its own vertical beside aggregates, including integration nodes.**

Danwa demonstrates aggregates, inline projections, and operations. Services using keiro-dsl's fuller vocabulary place the additional node kinds below, following the released generator and the `HospitalCapacity` example in keiro-runtime-jitsurei. This document decides where files live; the runtime and messaging documents explain what the generated contracts mean.

## First-Class Read Models

A `readmodel` node is a query model declared independently of an aggregate's inline projection. Use the generator's UpperCamelCase module segment for the node directory. The baseline modules are:

```text
<Service>/<Node>/Generated/ReadModel.hs
<Service>/<Node>/Generated/ReadModelHarness.hs
<Service>/<Node>/Generated/ReadModelTable.hs
<Service>/<Node>/ReadModelHoles.hs
```

A read model with declared query input and result types also generates `<Service>/<Node>/Generated/QueryContract.hs`. Use the emitted manifest for the complete module set.

Logical names such as `hospital_readiness`, `accepted_transfer_needs`, `transfer_candidates`, and `transfer_decisions` produce `HospitalReadiness`, `AcceptedTransferNeeds`, `TransferCandidates`, and `TransferDecisions` module segments. The underscore-bearing paths retained in the example repository are legacy output. Adopt current names through the [generated-name and edition migration](../keiro/generated-haskell-editions.md), preserving the logical DSL names and runtime identities.

## Processes, Workflows, And Routers

A `process` node is an event-sourced process manager: it reacts to facts and dispatches commands or timers. Place its generated behavior and harness beside the hand-owned decisions:

```text
<Service>/<Name>/Generated/Process.hs
<Service>/<Name>/Generated/ProcessHarness.hs
<Service>/<Name>/ProcessHoles.hs
```

A process written with Language 6 `reactions` also generates `Generated/Input.hs` for its typed input ADT, and its `ProcessHoles.hs` shrinks to the single create-once `decode<Process>Input :: RecordedEvent -> Maybe <Process>Input`; the pure reaction, timers, and firing dispatcher are generated. Use Language 6 from Keiro 0.17.0.0 onward; migrate legacy process bodies through the identity and drain checks in [evolution and rollout](../keiro/evolution-and-rollout.md).

`HospitalCapacity.HospitalSurge` is the reference realization. Process-state, timer, and dispatch semantics come from [process managers and durable timers](../messaging/process-managers.md).

A `workflow` node is a durable multi-step computation whose progress is journaled by keiro. Its generated vertical contains `Generated/WorkflowFacts.hs` and `Generated/WorkflowRuntime.hs`; the current generator does not create a workflow holes module. `HospitalCapacity.HospitalTransferReservation` is the reference realization. See [durable workflows](../keiro/durable-workflows.md) before choosing resume, timer, signal, and retention behavior.

A `router` node selects a target command from an input. Its vertical contains `Generated/Router.hs`, `Generated/RouterHarness.hs`, and hand-owned `RouterHoles.hs`. `HospitalCapacity.TransferNeedRouter` is the reference realization.

## Publishers, Inboxes, Queues, And Contracts

These integration-facing node kinds remain separate verticals:

```text
<Service>/<Publisher>/Generated/Publisher.hs
<Service>/<Inbox>/Generated/Inbox.hs
<Service>/<QueueNode>/Generated/Queue.hs
<Service>/<QueueNode>/Generated/QueuePolicy.hs
<Service>/<Contract>/Generated/Contract.hs
```

Use the current generated segments `HospitalPublisher`, `IncidentInbox`, `ReservationWork`, and `Emergency` for those example nodes. The example repository's `Reservation_work` directory is legacy output. Preserve the emitted placement and keep these modules in their node verticals.

The generated modules define checked structure, not a complete transport system. Apply the [integration event](../messaging/integration-events.md), [outbox](../messaging/outbox.md), [inbox](../messaging/inbox.md), [PGMQ job](../messaging/pgmq-jobs.md), and [transport-selection](../messaging/transport-selection.md) standards when filling the hand-owned runtime around them.

## Integration Is A Vertical

Integration is a first-class concept under `<Service>.Integration.*`, never a technical layer. Public contract types live in core. Producing reactors, outbox publishers, inbox consumers, and transport glue live in workers under the same namespace.

Danwa realizes this division with `danwa-core/src/Danwa/Integration/AddressedMessage.hs` and `danwa-workers/src/Danwa/Integration/{AddressedMessageWorker,OutboxPublisherWorker}.hs`. The richer example realizes hand-written `HospitalCapacity.Integration.{Contracts,Inbox,Outbox,KafkaConsumer,KafkaPublisher,ReservationWorkDispatch}` modules around generated nodes.

Do not mistake keiro-runtime-jitsurei's neighboring per-aggregate `Transducer`, `Projection`, `EventStream`, and `CommandProcessor` modules for part of this convention. They are a teaching-only legacy surface; the production aggregate convention is the generated ring plus only its declared create-once hooks, bindings, and witnesses. Language 6 generates expressible decisions; see [vertical-slice modules](vertical-slice-modules.md).

## Related Patterns

- [Vertical-slice modules](vertical-slice-modules.md)
- [Cross-cutting modules](cross-cutting-modules.md)
- [Process managers and durable timers](../messaging/process-managers.md)
- [Messaging glossary](../messaging/glossary.md)
- [Keiro-dsl adoption](../keiro/dsl-adoption.md)
