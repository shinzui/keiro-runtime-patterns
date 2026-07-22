# Read models and projections

**Register every read model at startup, fence every rebuild, and treat snapshots as advisory until history is truncated.**

This standard governs projection registration, consistency waits, asynchronous fencing, rebuilds, and the one condition that makes snapshots load-bearing.

## Register before serving queries

The rule is one sentence: call `registerReadModel` once for every model during projection startup, before any `runQuery` call.

An unregistered query returns `ReadModelUnregistered`; a stale version or `shapeHash` requires a rebuild. The `ReadModel.schema` field names the application-owned data schema but is deliberately absent from persisted registry identity. `subscriptionName`, `version`, and `shapeHash` bind the live projection contract.

`runQuery` checks registration and liveness before applying the model's consistency mode:

- `Eventual` queries immediately and is the correct default for inline-only models.
- `Strong` waits for `strongScope`: `EntireLog` or the declared `CategoryHead`.
- `PositionWait` waits for a caller-supplied global position and is preferred for read-your-write behavior.

## Choose inline or asynchronous application

Use `runCommandWithProjections` for state the command side must update atomically with its events. Projection failure aborts the append transaction.

Use `applyAsyncProjection` in subscription workers. Its `AsyncApplyOutcome` is part of the checkpoint protocol: acknowledge `AsyncApplied` and `AsyncDuplicate`; on `AsyncFenced`, do not checkpoint past the event—fail or park it until the model is live.

## Rebuild behind the fence

The rule is one sentence: rebuild with the supported three-phase protocol, never with ad hoc table truncation.

1. `startRebuild` marks the model `Rebuilding`, truncates its application table, clears named projection dedup keys, and resets its subscriptions in one transaction.
2. Replay through `applyAsyncProjectionUnfenced`; live workers continue using the fenced function.
3. Verify the result and call `finishRebuild`, or call `abandonRebuild` on failure.

This is an offline rebuild for that model, not a zero-downtime shadow-table swap.

## Keep snapshots advisory—with one exception

The glossary rule is normative: snapshots accelerate hydration but do not define aggregate truth while the complete replayable prefix remains in the event store. Missing, corrupt, or shape-mismatched snapshots fall back to full replay.

The exception is history truncation. Once Kiroku hides a per-stream prefix, a valid snapshot must cover that prefix; deleting it produces `HydrationGapDetected`. Restore visibility with the store's truncation controls or install a covering snapshot before resuming commands.

For depth, see the keiro repo's `docs/user/read-models-and-projections.md`, `docs/user/snapshots.md`, and `docs/guides/project-read-models.md`.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [The two-schema arrangement](two-schema-arrangement.md)
