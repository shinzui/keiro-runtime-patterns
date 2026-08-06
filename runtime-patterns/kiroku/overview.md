---
type: Overview
title: "Kiroku Event-Store Standards"
description: "Index of kiroku event-store standards for keiro services; start here"
timestamp: 2026-07-22T16:52:58Z
generated:
  by: human:nadeem
  at: "2026-07-22T16:52:58Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-overview
tags: [kiroku, overview]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T16:52:58Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved kiroku-project checkout (kiroku-store, adapters, otel, metrics) and the keiro consumer's Connection API; verified exported symbols, signatures, version claims, and links.
---

# Kiroku Event-Store Standards

**Start with the operational invariants, then learn the append and read contract before writing service code.**

This area is the fleet’s prescriptive Kiroku guide for Keiro services. It covers the event-store rules shared by command handlers, projections, subscriptions, operations, and observability.

## Start here

1. [Operational Invariants](./operational-invariants.md) — the ten production rules every service must preserve.
2. [Append and Read Patterns](./append-and-read.md) — concurrency, retry identity, cursors, and replay.
3. [Transactions and Projections](./transactions-and-projections.md) — the fleet-standard atomic append-plus-projection shape.

## Configure and operate

- [Connection Settings](./connection-settings.md) — schema, search path, pool, timeouts, and callbacks.
- [Subscriptions](./subscriptions.md) — at-least-once delivery, checkpoints, overflow, and consumer groups.
- [Observability](./observability.md) — metrics, tracing, endpoints, and health probes.
- [Lifecycle and Deletion](./lifecycle-and-deletion.md) — soft delete, hard delete, compaction, and linked streams.

## Related Patterns

- [Keiki Transducer Standards](../keiki/overview.md)
- [Migration Standards](../migrations/overview.md)
