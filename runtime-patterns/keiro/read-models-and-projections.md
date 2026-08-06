---
type: Standard
title: "Read models and projections"
description: "Read-model registration, consistency, async fencing, rebuilds, and snapshot limits"
timestamp: 2026-08-06T02:47:25Z
generated:
  by: human:nadeem
  at: "2026-08-06T02:47:25Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-read-models-and-projections
tags: [keiro, read-models-and-projections]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-23T23:55:16Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

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

## Match all three snapshot discriminator components

An aggregate snapshot is loaded only when three independent components agree:

1. `stateCodecVersion`, owned manually by the service;
2. `shapeHash`, the register-layout identity;
3. `stateShapeHash`, the control-state and replay-fold identity.

`defaultStateCodec` derives the third through keiki's `CanonicalStateShape`, so register-layout and control-state changes invalidate stale seeds automatically. Generated codecs compose a spec-derived fold fingerprint as `<state-hash>;fold=<fingerprint>` through `withFoldFingerprint`; hand-written services may supply and maintain their own token the same way.

The manual clause is still load-bearing. **A fold or guard change the derivation cannot see — hand-written update logic, or logic living only in a generated service's hand-owned Holes module — must bump `stateCodecVersion`.** Nothing else will catch it: an unbumped invisible change presents identical discriminators by construction. As a backstop, one accepted seed in 1000 is verified against a full replay, and a mismatch increments `keiro.snapshot.seed.divergence`; alert on that metric.

Rows written before the discriminator gained its third component carry an empty sentinel. They miss once, full-replay, and may then be replaced with a current seed, so expect a one-time replay cost per stream after the upgrade.

Keiro 0.9 widened the fold fingerprint from a 16-hex-digit FNV-1a-64 to a 32-hex-digit FNV-1a-128 value. The widening is deliberate and invalidates every snapshot discriminated by the earlier token: after the upgrade each stream misses once and rebuilds from events. Plan the replay cost and refresh generated transducers; do not attempt to translate old tokens. Read-model, mapped-wire, and behavior-key identities are separate 64-bit values and did not move.

For depth, see the keiro repo's `docs/user/read-models-and-projections.md`, `docs/user/snapshots.md`, and `docs/guides/project-read-models.md`.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [The two-schema arrangement](two-schema-arrangement.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
