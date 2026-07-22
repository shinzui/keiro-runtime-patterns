# Kiroku Lifecycle and Deletion

**Prefer reversible lifecycle controls, and isolate irreversible erasure behind explicit authorization and audit.**

Use this guide for soft deletion, physical erasure, logical prefix compaction, and linked streams. These APIs have deliberately different effects on per-stream reads and the global log.

## Prefer soft deletion for reversible state

`softDeleteStream` hides a stream from ordered per-stream reads and append operations. Its events remain visible in `$all` and category history. `undeleteStream` restores the row and its complete history. Use this when the domain state is inactive or hidden but its audit history must remain.

## Isolate hard deletion

`hardDeleteStream` physically removes the stream and orphaned events, including their visibility in `$all`. The interpreter sets `SET LOCAL kiroku.enable_hard_deletes = 'on'` so deletion triggers allow the operation.

That GUC is advisory protection against accidental SQL, not a security boundary: any session with `DELETE` privilege can set it. The normal application role should not have `DELETE` on Kiroku data tables. Route erasure through a separately privileged and authorized operation.

Before hard deletion, append an application-level erasure-decision event that records who authorized the action, why it was required, and when it occurred. Kiroku’s physical deletion does not create an in-band audit event of its own.

## Use `truncateBefore` only for read compaction

After appending a snapshot at version V, `setStreamTruncateBefore stream V` makes ordered per-stream reads start at that version. It does not delete earlier events and does not affect `$all`, category reads, subscriptions, or membership probes. `clearStreamTruncateBefore` restores the full per-stream read history.

Do not call this retention or erasure. It is a reversible read-start marker for snapshot-based rehydration.

## Avoid building new patterns on linked streams

`linkToStream` shares existing events into another stream and assigns target-stream versions while preserving original identity and global position. The API is provisional: the Keiro codebase has zero known consumers, and future Kiroku storage changes may remove or redesign it. Do not introduce a fleet pattern that depends on linked streams without a new architecture decision.

## Related Patterns

- [Append and Read Patterns](./append-and-read.md)
- [Operational Invariants](./operational-invariants.md)
- [Subscriptions](./subscriptions.md)

