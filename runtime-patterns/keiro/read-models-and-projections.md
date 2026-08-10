---
type: Standard
title: "Read models and projections"
description: "Typed read-model queries and consistency, catalog-backed projection application, and snapshot limits"
timestamp: 2026-08-10T13:59:20Z
generated:
  by: human:nadeem
  at: "2026-08-10T13:59:20Z"
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

**Register typed queries before serving them, apply projections through the validated catalog, and treat snapshots as advisory until history is truncated.**

This standard governs projection ownership, registration, consistency waits, asynchronous fencing, rebuilds, and the one condition that makes snapshots load-bearing.

## Declare one read-side inventory

Every service must build and validate one `ProjectionCatalog`, then use the resulting `ValidatedProjectionCatalog` for registration, live projection selection, rebuilds, and operator inventory. The catalog keeps query-model bindings, physical targets, rebuild groups, owners, source identities, and reset and replay policies explicit.

The full closed-world validation and group-rebuild rules live in [typed projection catalogs and rebuild groups](projection-catalogs.md). Candidate Language 5 can generate the catalog facade and mapped query aliases; until that contract is released and adopted, a hand-written catalog is the supported bridge.

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

Drive rebuilds through `ProjectionCatalogOperations`, never caller-supplied table, subscription, or projection lists. Fence the complete dependency group, capture one immutable event-store head, replay deterministic bounded pages, persist resumable evidence, run every declared verification, and promote only when all sources prove exhaustion. A failed or abandoned run stays fenced.

This is an offline rebuild, not a zero-downtime shadow-table swap. Preview and operate it through the mounted [Keiro operations console](operations-console.md); the complete lifecycle is specified by [typed projection catalogs and rebuild groups](projection-catalogs.md).

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
- [Typed projection catalogs and rebuild groups](projection-catalogs.md)
- [Mapped consumer surfaces](mapped-consumer-surfaces.md)
- [Keiro operations console](operations-console.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [The two-schema arrangement](two-schema-arrangement.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
