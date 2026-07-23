# Guide

- [Kiroku Lifecycle and Deletion](lifecycle-and-deletion.md) - Soft and hard deletion, the advisory hard-delete GUC, truncateBefore compaction, and provisional linkToStream
- [Kiroku Observability](observability.md) - Wiring kiroku-metrics and kiroku-otel: collector composition, spans, Prometheus names, health probes

# Overview

- [Kiroku Event-Store Standards](overview.md) - Index of kiroku event-store standards for keiro services; start here

# Runbook

- [Kiroku Operational Invariants](operational-invariants.md) - The ten invariants every kiroku-backed service must respect in production

# Standard

- [Kiroku Append and Read Patterns](append-and-read.md) - ExpectedVersion semantics, idempotent retries via supplied event ids, and streaming reads
- [Kiroku Connection Settings](connection-settings.md) - Store schema and NOTIFY channel, extraSearchPath seam, timeouts, and synchronous handler discipline
- [Kiroku Subscription Patterns](subscriptions.md) - At-least-once subscriptions, per-batch checkpoints, overflow policies, and Serial consumer groups
- [Kiroku Transactions and Projections](transactions-and-projections.md) - Atomic append plus projection with runTransactionAppendingResource, and why the other combinators are traps

