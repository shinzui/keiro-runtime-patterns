---
type: Standard
title: "Kiroku Replay-History Retention"
description: "Holding a renewable retention lease so a long replay sees stable history, and how that lease refuses destructive work"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-history-retention
tags: [kiroku, history-retention]
status: current
---

# Kiroku Replay-History Retention

**Any process that replays history for longer than one transaction must hold a retention lease for the whole replay, and must abandon rather than reacquire when the lease lapses.**

Kiroku Store 0.7 makes "the retained event set will not move under me" a durable database fact instead of an assumption. `Kiroku.Store.HistoryRetention` exposes the lease lifecycle both as transaction combinators and through the mockable `Store` effect; migration `0010` installs the lease tables, the schema-local coordinator, and the statement-level guards.

## Acquire before the first page, not after a failure

`acquireHistoryRetentionLease` takes a validated owner (1–512 UTF-8 bytes), a validated reason (1–2,048 UTF-8 bytes), and a duration between one second and one hour. Acquisition atomically captures the authoritative `$all` frontier as the lease's inclusive `protectedThrough` ceiling — the rebuild's own replay ceiling and the retention promise are the same fact, established at the same instant.

Renew with `renewHistoryRetentionLease` on a schedule comfortably inside the duration. Renewal never shortens the current expiry, and unknown, wrong-owner, expired, and released leases return distinct typed errors and are never resurrected. Release explicitly with `releaseHistoryRetentionLease`; repeating a release is typed and does not rewrite the row.

Expiry is passive and database-derived: a crashed owner blocks destructive work only until PostgreSQL time reaches `expiresAt`, and no expiry worker exists. Set the duration from the real page cadence, not from the expected total replay time.

**An expired or unrenewable lease invalidates the work it was protecting.** Do not acquire a fresh lease and continue: between the lapse and the new acquisition, history may have moved. Abandon the run and restart it under a new lease.

## Treat the owner as an accidental-mutation guard, not authorization

The owner label exists so one process cannot renew or release another's lease by accident. It is not a credential. Database roles and grants remain the only security boundary, exactly as they are for [hard deletion](lifecycle-and-deletion.md).

## Expect hard delete and direct SQL to refuse

While any lease is active:

- supported `hardDeleteStream` checks retention before mutating and returns `StoreError`'s `HistoryRetentionActive`, carrying the refused stream plus the active-lease count and earliest expiry;
- direct `DELETE` or `TRUNCATE` against `kiroku.events`, `kiroku.stream_events`, or `kiroku.streams` raises SQLSTATE `KR001` from a statement-level trigger, **even with the `kiroku.enable_hard_deletes` GUC set**.

The GUC and the lease are independent controls with different purposes: the GUC guards against unintended erasure, the lease guards a specific in-flight replay. Operators must plan an erasure window around active leases rather than expecting one control to override the other.

Kiroku's own `KR001` means "replay history is protected by an active retention lease". Keiro's guarded external-read wrappers use the same SQLSTATE for a different, unrelated condition; classify by the function you called, never by the SQLSTATE alone. See [read models and projections](../keiro/read-models-and-projections.md).

## Serialize a replay against the stream it reads

For per-stream repair, `lockStreamHistoryForReplayTx` holds a transaction-scoped guard on one stream and `readStreamForwardTx` reads its exact ordered history in that same transaction. Append, link, lifecycle mutation, and every supported hard delete affecting that stream serialize behind the guard. Supported hard delete locks every affected stream in ascending ID order, including streams holding links to target-originated events, so a hand-written deletion that locks in another order can deadlock against it.

When one transaction needs both a lease operation and a stream guard, **perform the lease operation first**. That preserves Kiroku's coordinator-before-stream-row lock order.

## Prune deliberately; leases are evidence

Lease rows survive expiry and release on purpose: they are the durable record of which process protected which frontier and why. `pruneHistoryRetentionLeases` removes only expired or released rows strictly older than a supplied cutoff, and never touches an active lease. Read the current picture with the bounded `historyRetentionLeaseInventory` (1–1,000 rows) rather than querying the lease table directly, and keep pruning on an explicit operational schedule instead of inside rebuild code.

## Extend custom interpreters before upgrading

The exported `Store` effect gains acquire, renew, release, inventory, and prune constructors, `KirokuEvent` gains committed acquisition, renewal, release, prune, and hard-delete-conflict events, and `StoreError` gains `HistoryRetentionActive`. Exhaustive custom and mock interpreters and event handlers must handle all of them. The transaction combinators deliberately emit no process-local observability events, because they run inside an opaque caller-owned transaction; only the effect wrappers publish committed events.

## Related Patterns

- [Lifecycle and Deletion](lifecycle-and-deletion.md)
- [Append and Read Patterns](append-and-read.md)
- [Operational Invariants](operational-invariants.md)
- [Read models and projections](../keiro/read-models-and-projections.md)
- [Targeted stream-scoped projection repair](../keiro/stream-scoped-repair.md)
