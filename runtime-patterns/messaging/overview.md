---
type: Overview
title: "Keiro Messaging Patterns"
description: "Index of messaging standards for keiro services: process managers, integration events, transports; start here"
timestamp: 2026-07-22T11:27:32-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-overview
tags: [messaging, overview]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T11:27:32-07:00
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

- [Process managers and durable timers](process-managers.md) — saga state, deterministic dispatch, worker policies, timers, and the orchestration decision ladder.

## Talking To Other Services

- [Integration events](integration-events.md) — the public envelope, identity, versioning, ordering, and trace propagation contract.
- [Transactional outbox](outbox.md) — safely record and publish outbound integration events.
- [Idempotent inbox](inbox.md) — deduplicate inbound integration events with their local effects.

## The Processing Substrate

- [Shibuya processing](shibuya-processing.md) — acknowledgement intent, finalization, concurrency, batching, supervision, and shutdown.
- [Transport selection](transport-selection.md) — choose among PGMQ, Kafka, and Kiroku subscriptions.
- [Typed PGMQ jobs](pgmq-jobs.md) — background work, retry policy, visibility timeout, FIFO groups, and queue identity.
- [Kiroku subscriptions](kiroku-subscriptions.md) — consume a service's own event log through Shibuya.

## Before Production

- [Messaging gotchas](gotchas.md) — failure modes that must be addressed in design and operations.

## Related Patterns

- [Keiki transducer patterns](../keiki/overview.md) — the durable state-machine layer under aggregates and manager streams.
- [Keiro runtime patterns](../keiro/overview.md) — assembly, schemas, command errors, read models, workflows, telemetry, and DSL adoption.
