---
type: Overview
title: "Kiroku Event-Store Standards"
description: "Index of kiroku event-store standards for keiro services; start here"
timestamp: 2026-07-22T09:52:58-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-overview
tags: [kiroku, overview]
status: current
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
