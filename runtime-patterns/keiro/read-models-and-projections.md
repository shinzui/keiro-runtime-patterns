---
type: Standard
title: "Read models and projections"
description: "Typed projection catalogs, group fencing, deterministic resumable rebuilds, consistency, and snapshot limits"
timestamp: 2026-08-09T16:56:58Z
generated:
  by: human:nadeem
  at: "2026-08-09T16:56:58Z"
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

**Declare one validated projection catalog, fence and rebuild whole dependency groups through it, and treat snapshots as advisory until history is truncated.**

This standard governs projection ownership, registration, consistency waits, asynchronous fencing, rebuilds, and the one condition that makes snapshots load-bearing.

## Declare one read-side inventory

Every new service must build one `ProjectionCatalog`, validate it, and use only the resulting `ValidatedProjectionCatalog` for registration, live projection selection, rebuilds, and operator inventory. The catalog keeps four identities separate:

- a typed query-model binding describes what a query observes;
- a physical target identifies one application-owned table and its reset policy;
- a rebuild group orders targets that must fence, reset, verify, and promote together; and
- one projection owner describes the source, targets, live handlers, and explicit replay behavior.

Catalog validation must prove that every target has exactly one owner, every reference resolves, no owner crosses rebuild groups, target dependencies are acyclic and correctly ordered, and clear-before-replay targets have replayable owners. Persist and compare the catalog inventory so deleting a target and its owner together cannot disappear undetected. Validation is closed-world: inventory arbitrary application SQL and every external writer separately.

Candidate Language 5 generates the catalog facade and create-once handler holes. Until that language is released and adopted, a hand-written catalog is the supported bridge; unmanaged compatibility wrappers are migration tools, not the baseline for a new service.

This catalog contract is the unreleased source outcome of `mori://shinzui/keiro/masterplans/32-build-typed-projection-catalogs-and-safe-coordinated-rebuilds`. Its explicit missing-checkpoint lifecycle follow-up is tracked by `mori://shinzui/keiro/masterplans/33-make-subscription-checkpoint-lifecycle-explicit-before-the-next-release`; complete both before treating the next package cohort as a new-service baseline.

## Register before serving queries

Call `registerProjectionCatalog` once during projection startup, before any `runQuery` call or projection worker. Refuse startup on validation or fingerprint drift. An unregistered query returns `ReadModelUnregistered`; a stale version or `shapeHash` requires a rebuild.

`runQuery` checks registration and liveness before applying the model's consistency mode:

- `Eventual` queries immediately and is the correct default for inline-only models.
- `Strong` waits for `strongScope`: `EntireLog` or the declared `CategoryHead`.
- `PositionWait` waits for a caller-supplied global position and is preferred for read-your-write behavior.

## Choose inline or asynchronous application

Use `runCommandWithCatalogProjections` for state the command side must update atomically with its events. It derives the handlers and rebuild-group locks from the validated catalog; projection failure or a fenced group aborts the append transaction.

Use `applyAsyncProjectionFromCatalog` in subscription workers. Its `AsyncApplyOutcome` is part of the checkpoint protocol: acknowledge `AsyncApplied` and `AsyncDuplicate`; on `AsyncFenced`, do not checkpoint past the event—fail or park it until the group is live.

Handlers must derive time-dependent values from recorded event time or payload data. `NOW()`, wall-clock reads, random values, network calls, and other ambient effects make replay diverge from the live result. Keep external side effects out of replay adapters.

## Rebuild one dependency group behind the fence

The rule is one sentence: drive rebuilds from the validated catalog, never from caller-supplied table, subscription, or projection lists.

1. `startCatalogRebuild` invokes the group preparation lifecycle to fence the whole group, capture its declared identities, clear every `ClearBeforeReplay` target with one foreign-key-safe multi-table `TRUNCATE`, preserve reconcile-only targets, and reset only replayable subscription and dedup identities.
2. The runner captures an immutable event-store head and replays deterministic bounded pages through explicit catalog adapters. It persists source cursors, adapter counts, the catalog fingerprint, and failure evidence so `resumeCatalogRebuild` can continue the same run.
3. Run every declared verification hook. Promote only when all sources prove exhaustion through the captured head and all verification passes. On failure, abandon the run and keep the group fenced.

`PreserveAndReconcile` and `LiveOnly` are honest brownfield policies, not lesser forms of `ClearBeforeReplay` and `Replayable`. Reset policy says what preparation does to a target; replay policy says whether history can reconstruct it. Keep those decisions independent. The legacy single-read-model lifecycle is a compatibility path and cannot safely coordinate foreign-key-linked targets.

This is an offline rebuild for the group, not a zero-downtime shadow-table swap. Preview and operate it through the catalog-backed operations adapter so application CLIs do not maintain a second rebuild map.

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
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [The two-schema arrangement](two-schema-arrangement.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
