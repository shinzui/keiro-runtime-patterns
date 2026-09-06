# Guide

- [Kiroku Lifecycle and Deletion](lifecycle-and-deletion.md) - Soft and hard deletion, the advisory hard-delete GUC, retention-lease refusal, truncateBefore compaction, and provisional linkToStream
- [Kiroku Observability](observability.md) - Wiring kiroku-metrics and kiroku-otel: collector composition, spans, Prometheus names, health probes

# Overview

- [Kiroku Event-Store Standards](overview.md) - Index of Kiroku Store 0.8 standards, including retryable transaction failures, checkpoint inventory, and replay-history retention

# Runbook

- [Kiroku Operational Invariants](operational-invariants.md) - The ten invariants every kiroku-backed service must respect in production

# Standard

- [Kiroku Append and Read Patterns](append-and-read.md) - ExpectedVersion semantics, idempotent retries via supplied event ids, and streaming reads
- [Kiroku durable checkpoint inventory](checkpoint-inventory.md) - Reading one member-aware durable checkpoint snapshot in-process or through the frozen v1 relation, without mislabeling cursor distance as event lag
- [Kiroku Connection Settings](connection-settings.md) - Store schema and NOTIFY channel, extraSearchPath seam, timeouts, and synchronous handler discipline
- [Kiroku Replay-History Retention](history-retention.md) - Holding a renewable retention lease so a long replay sees stable history, and how that lease refuses destructive work
- [Kiroku Subscription Patterns](subscriptions.md) - At-least-once subscriptions, explicit first-run checkpoint intent, durable checkpoint inventory, overflow policies, and Serial consumer groups
- [Kiroku Transactions and Projections](transactions-and-projections.md) - Atomic append plus projection with runTransactionAppendingResource, and why the other combinators are traps

