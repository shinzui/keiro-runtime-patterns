---
type: Pattern
title: "Extended Keiro-DSL Node Verticals"
description: "Where read models, process managers, workflows, routers, publishers, inboxes, queues, and contracts sit in the slice"
timestamp: 2026-07-22T18:42:26Z
generated:
  by: human:nadeem
  at: "2026-07-22T18:42:26Z"
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
---

# Extended Keiro-DSL Node Verticals

**Every first-class DSL node gets its own vertical beside aggregates, including integration nodes.**

Danwa demonstrates aggregates, inline projections, and operations. Services using keiro-dsl's fuller vocabulary place the additional node kinds below, following the released generator and the `HospitalCapacity` example in keiro-runtime-jitsurei. This document decides where files live; the runtime and messaging documents explain what the generated contracts mean.

## First-Class Read Models

A `readmodel` node is a query model declared independently of an aggregate's inline projection. Put its three generated modules and one hand-owned hole in a directory named exactly after the DSL node:

```text
<Service>/<Node>/Generated/ReadModel.hs
<Service>/<Node>/Generated/ReadModelHarness.hs
<Service>/<Node>/Generated/ReadModelTable.hs
<Service>/<Node>/ReadModelHoles.hs
```

The directory retains the DSL node's snake_case spelling instead of converting it to ordinary Haskell CamelCase. The realized paths include `HospitalCapacity/Hospital_readiness`, `Accepted_transfer_needs`, `Transfer_candidates`, and `Transfer_decisions`. Those underscores are generated identity, not typographical errors.

## Processes, Workflows, And Routers

A `process` node is an event-sourced process manager: it reacts to facts and dispatches commands or timers. Place its generated behavior and harness beside the hand-owned decisions:

```text
<Service>/<Name>/Generated/Process.hs
<Service>/<Name>/Generated/ProcessHarness.hs
<Service>/<Name>/ProcessHoles.hs
```

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

Keiro-runtime-jitsurei realizes them as `HospitalPublisher`, `IncidentInbox`, snake_case `Reservation_work`, and `Emergency`. Preserve the emitted node spelling and never relocate these modules into a catch-all `Generated.Integration` tree.

The generated modules define checked structure, not a complete transport system. Apply the [integration event](../messaging/integration-events.md), [outbox](../messaging/outbox.md), [inbox](../messaging/inbox.md), [PGMQ job](../messaging/pgmq-jobs.md), and [transport-selection](../messaging/transport-selection.md) standards when filling the hand-owned runtime around them.

## Integration Is A Vertical

Integration is a first-class concept under `<Service>.Integration.*`, never a technical layer. Public contract types live in core. Producing reactors, outbox publishers, inbox consumers, and transport glue live in workers under the same namespace.

Danwa realizes this division with `danwa-core/src/Danwa/Integration/AddressedMessage.hs` and `danwa-workers/src/Danwa/Integration/{AddressedMessageWorker,OutboxPublisherWorker}.hs`. The richer example realizes hand-written `HospitalCapacity.Integration.{Contracts,Inbox,Outbox,KafkaConsumer,KafkaPublisher,ReservationWorkDispatch}` modules around generated nodes.

Do not mistake keiro-runtime-jitsurei's neighboring per-aggregate `Transducer`, `Projection`, `EventStream`, and `CommandProcessor` modules for part of this convention. They are a teaching-only legacy surface; the production aggregate convention remains one generated ring plus one hand-owned `Holes` module.

## Related Patterns

- [Vertical-slice modules](vertical-slice-modules.md)
- [Cross-cutting modules](cross-cutting-modules.md)
- [Process managers and durable timers](../messaging/process-managers.md)
- [Messaging glossary](../messaging/glossary.md)
- [Keiro-dsl adoption](../keiro/dsl-adoption.md)
