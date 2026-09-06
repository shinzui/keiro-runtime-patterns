---
type: Overview
title: "Kiroku Event-Store Standards"
description: "Index of Kiroku Store 0.8 standards, including retryable transaction failures, checkpoint inventory, and replay-history retention"
timestamp: 2026-09-06T21:22:15Z
generated:
  by: process:codex
  at: "2026-09-06T21:22:15Z"
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

Keiro 0.15.0.0 requires `kiroku-store >=0.8 && <0.9` and `kiroku-store-migrations ^>=0.4.0.0`. Store 0.8 adds the retryable `TransientTransactionFailure` constructor; extend exhaustive error matches and apply [bounded retry](transactions-and-projections.md). Earlier releases also extended the `Store` effect, so update custom or mock interpreters when crossing them: 0.5 makes the [first-run checkpoint decision explicit](./subscriptions.md) and adds the transactional reset; 0.6 adds the [visible global head](./append-and-read.md); 0.7 adds [replay-history retention leases](./history-retention.md), the transaction-scoped stream guard, and the `HistoryRetentionActive` refusal. On the migration side, `0009` publishes the frozen [checkpoint relation](./checkpoint-inventory.md) and corrected `0010` plus `0011` install and converge the retention schema on `kiroku.uuidv7()`. Databases that applied withdrawn `0010` require the [guarded checksum recovery](../migrations/operations.md) before normal migration; Hackage deprecates migration releases 0.3.2.0 and 0.3.2.1.

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
