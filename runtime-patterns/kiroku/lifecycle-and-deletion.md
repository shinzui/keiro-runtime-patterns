---
type: Guide
title: "Kiroku Lifecycle and Deletion"
description: "Soft and hard deletion, the advisory hard-delete GUC, retention-lease refusal, truncateBefore compaction, and provisional linkToStream"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-lifecycle-and-deletion
tags: [kiroku, lifecycle-and-deletion]
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

# Kiroku Lifecycle and Deletion

**Prefer reversible lifecycle controls, and isolate irreversible erasure behind explicit authorization and audit.**

Use this guide for soft deletion, physical erasure, logical prefix compaction, and linked streams. These APIs have deliberately different effects on per-stream reads and the global log.

## Prefer soft deletion for reversible state

`softDeleteStream` hides a stream from ordered per-stream reads and append operations. Its events remain visible in `$all` and category history. `undeleteStream` restores the row and its complete history. Use this when the domain state is inactive or hidden but its audit history must remain.

## Isolate hard deletion

`hardDeleteStream` physically removes the stream and orphaned events, including their visibility in `$all`. The interpreter sets `SET LOCAL kiroku.enable_hard_deletes = 'on'` so deletion triggers allow the operation.

That GUC is advisory protection against accidental SQL, not a security boundary: any session with `DELETE` privilege can set it. The normal application role should not have `DELETE` on Kiroku data tables. Route erasure through a separately privileged and authorized operation.

Before hard deletion, append an application-level erasure-decision event that records who authorized the action, why it was required, and when it occurred. Kiroku’s physical deletion does not create an in-band audit event of its own.

Hard deletion also checks replay-history retention before it mutates anything, and fails with `HistoryRetentionActive` while any lease is live. Direct `DELETE` or `TRUNCATE` against `kiroku.events`, `kiroku.stream_events`, or `kiroku.streams` raises SQLSTATE `KR001` from a statement-level trigger even with the GUC enabled. The two controls are independent: plan an erasure window around active leases rather than expecting either one to override the other. See [replay-history retention](history-retention.md).

Supported hard delete locks every affected stream in ascending stream-ID order, including streams holding links to target-originated events. A hand-written deletion that acquires those rows in another order can deadlock against it.

## Use `truncateBefore` only for read compaction

After appending a snapshot at version V, `setStreamTruncateBefore stream V` makes ordered per-stream reads start at that version. It does not delete earlier events and does not affect `$all`, category reads, subscriptions, or membership probes. `clearStreamTruncateBefore` restores the full per-stream read history.

Do not call this retention or erasure. It is a reversible read-start marker for snapshot-based rehydration.

Move the marker only after proving snapshot coverage. The [Keiro operations console](../keiro/operations-console.md) enforces that order: `snapshot truncation-preflight --before VERSION` checks coverage against the discriminators you supply, and `stream truncate-before set` is the previewed mutation that follows it. `stream clear` restores full per-stream reads. Route soft delete, undelete, and hard delete through the same console rather than ad-hoc SQL, so each one carries a preview, a typed confirmation, and durable operator evidence.

## Avoid building new patterns on linked streams

`linkToStream` shares existing events into another stream and assigns target-stream versions while preserving original identity and global position. The API is provisional: the Keiro codebase has zero known consumers, and future Kiroku storage changes may remove or redesign it. Do not introduce a fleet pattern that depends on linked streams without a new architecture decision.

## Related Patterns

- [Append and Read Patterns](./append-and-read.md)
- [Replay-History Retention](./history-retention.md)
- [Keiro operations console](../keiro/operations-console.md)
- [Operational Invariants](./operational-invariants.md)
- [Subscriptions](./subscriptions.md)
