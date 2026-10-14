---
type: Overview
title: "Keiro Messaging Patterns"
description: "Index of messaging standards for Keiro services, including pgmq-hs 0.6 queue lifecycle and reconciliation"
timestamp: 2026-10-14T21:58:53Z
generated:
  by: process:codex
  at: "2026-10-14T21:58:53Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-overview
tags: [messaging, overview]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T18:27:32Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved shibuya 0.8.0.1, shibuya-{kafka,pgmq,kiroku,message-db} adapters, keiro 0.4.0.1, and kiroku source; verified exported symbols, signatures, version claims, and links.
---

# Keiro Messaging Patterns

**How keiro services orchestrate internally and talk to each other: the standards index.**

Use this area for process managers, public integration contracts, transactional handoffs, and the Shibuya transports that carry asynchronous work. Start with the glossary, then follow the path matching the behavior you are building.

## Shared Vocabulary

- [Messaging glossary](glossary.md) — domain and integration events, outbox, inbox, acknowledgements, delivery, and transport terms.

## Orchestrating Inside A Service

- [Process managers and durable timers](process-managers.md) — saga state, deterministic dispatch, the typed reaction runner (`Keiro.ProcessManager.Reaction`), worker policies, timers, and the orchestration decision ladder.

## Talking To Other Services

- [Integration events](integration-events.md) — the public envelope, identity, versioning, ordering, and trace propagation contract.
- [Transactional outbox](outbox.md) — safely enqueue outbound integration events, classify terminal rejection, and finalize publication outcomes atomically.
- [Idempotent inbox](inbox.md) — deduplicate inbound integration events with their local effects, or delegate the receipt to the downstream state transition.

## The Processing Substrate

- [Shibuya processing](shibuya-processing.md) — acknowledgement intent, application dead-letter codes, finalization, concurrency, batching, supervision, and shutdown.
- [Transport selection](transport-selection.md) — choose among PGMQ, Kafka, and Kiroku subscriptions.
- [Typed PGMQ jobs](pgmq-jobs.md) — background work, required job ordering and FIFO-heads, retry policy, visibility timeout, DLQ retention, and queue identity.
- [PGMQ queue lifecycle and reconciliation](pgmq-queue-reconciliation.md) — validated physical names, PGMQ 1.13 schema, additive provisioning, partition premake and spill, drift, notifications, and retry classification.
- [PGMQ connection faults and retry budgets](pgmq-connection-faults.md) — what a restart, backend termination, or TCP reset looks like to the runtime, adapter poll and ack budgets, exhaustion under supervision, and idempotent enqueues under lost replies.
- [Kiroku subscriptions](kiroku-subscriptions.md) — consume a service's own event log through Shibuya.

## Before Production

- [Messaging gotchas](gotchas.md) — failure modes that must be addressed in design and operations.

## Inspect the processing runtime

Use [Shibuya health and inspection](shibuya-inspection.md) for the released lifecycle, health and WebSocket contract. Use [Kiroku read-only inspection](../kiroku/inspection.md) for durable browsing, checkpoint/dead-letter truth and recoverable live tails.

## Related Patterns

- [Keiki transducer patterns](../keiki/overview.md) — the durable state-machine layer under aggregates and manager streams.
- [Keiro runtime patterns](../keiro/overview.md) — assembly, schemas, command errors, read models, workflows, telemetry, and DSL adoption.
