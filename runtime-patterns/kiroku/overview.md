---
type: Overview
title: "Kiroku Event-Store Standards"
description: "Index of Kiroku Store 0.7 event-store standards for Keiro services, including checkpoint inventory and replay-history retention"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
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

Keiro 0.12.0.0 requires `kiroku-store >=0.7 && <0.8` and `kiroku-store-migrations ^>=0.3.2.0`. Three cycles land in that range and each one adds a `Store` effect constructor, so an exhaustive custom or mock interpreter must be extended before upgrading: 0.5 makes the [first-run checkpoint decision explicit](./subscriptions.md) and adds the transactional reset; 0.6 adds the [visible global head](./append-and-read.md); 0.7 adds [replay-history retention leases](./history-retention.md), the transaction-scoped stream guard, and the `HistoryRetentionActive` refusal. On the migration side, `0009` publishes the frozen [checkpoint relation](./checkpoint-inventory.md) and `0010` installs the retention tables and destructive-statement guards.

## Start here

1. [Operational Invariants](./operational-invariants.md) — the ten production rules every service must preserve.
2. [Append and Read Patterns](./append-and-read.md) — concurrency, retry identity, cursors, and replay.
3. [Transactions and Projections](./transactions-and-projections.md) — the fleet-standard atomic append-plus-projection shape.

## Configure and operate

- [Connection Settings](./connection-settings.md) — schema, search path, pool, timeouts, and callbacks.
- [Subscriptions](./subscriptions.md) — at-least-once delivery, checkpoints, overflow, and consumer groups.
- [Durable Checkpoint Inventory](./checkpoint-inventory.md) — one coherent, member-aware read of durable positions without private table queries.
- [Observability](./observability.md) — metrics, tracing, endpoints, and health probes.
- [Lifecycle and Deletion](./lifecycle-and-deletion.md) — soft delete, hard delete, compaction, and linked streams.
- [Replay-History Retention](./history-retention.md) — hold a renewable lease for a long replay, and know what it refuses.

## Related Patterns

- [Keiki Transducer Standards](../keiki/overview.md)
- [Migration Standards](../migrations/overview.md)
