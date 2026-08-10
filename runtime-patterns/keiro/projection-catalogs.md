---
type: Standard
title: "Typed projection catalogs and rebuild groups"
description: "One validated projection inventory, catalog-derived live writers, dependency-group fencing, and deterministic resumable rebuilds"
timestamp: 2026-08-10T13:59:20Z
generated:
  by: human:nadeem
  at: "2026-08-10T13:59:20Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-projection-catalogs
tags: [keiro, projection-catalogs]
status: current
---

# Typed projection catalogs and rebuild groups

**Build one closed-world `ProjectionCatalog`, validate it once, and derive every live writer and rebuild action from that same value.**

This is a post-0.11 source contract. It is not part of the released Keiro 0.11.0.0 package cohort. Adopt it only from a coherent Keiro revision that completes `mori://shinzui/keiro/masterplans/32-build-typed-projection-catalogs-and-safe-coordinated-rebuilds` and its checkpoint-lifecycle follow-up `mori://shinzui/keiro/masterplans/33-make-subscription-checkpoint-lifecycle-explicit-before-the-next-release`.

## Keep every identity explicit

The catalog must declare all of these separately:

- a typed query-model binding for what an application query observes;
- a physical target for one application-owned table and its reset policy;
- a rebuild group for targets that fence, prepare, verify, and promote together;
- a projection owner for one source, its ordered handlers, owned targets, and replay policy;
- every asynchronous subscription and deduplication identity used by those handlers.

Validation must reject duplicate ownership, unresolved references, cross-group ownership, dependency cycles, wrong handler order, and a clear-before-replay target with no replayable owner. Persist and compare the inventory so removing a target and its owner together cannot disappear as an apparently clean startup. Inventory application SQL and external writers separately; catalog validation is closed-world only over what the application declares.

Candidate Language 5 can generate the catalog facade and create-once handler holes. A hand-written catalog is the bridge for earlier language contracts; unmanaged wrappers are migration aids, not the new-service baseline.

## Register before any reader or writer starts

Call `registerProjectionCatalog` once after migrations and catalog validation, before queries, command-side projection writes, or asynchronous workers. Refuse startup on validation failure, catalog-fingerprint drift, or incompatible registered query metadata.

Derive typed query registrations, inline projection sets, asynchronous handlers, inventory, and operations from the validated value. Do not keep parallel maps in startup code, workers, or an operations executable.

Use `runCommandWithCatalogProjections` for inline state that must commit with its source events. Use `applyAsyncProjectionFromCatalog` for subscription-driven state. Treat `AsyncApplyOutcome` as checkpoint protocol: acknowledge `AsyncApplied` and `AsyncDuplicate`; do not checkpoint an `AsyncFenced` delivery past a group that is rebuilding.

## Separate reset policy from replay policy

`ClearBeforeReplay` means preparation clears a target; `PreserveAndReconcile` means it retains brownfield state. `Replayable` means history has a total replay adapter; `LiveOnly` names why it does not. These decisions are independent.

A clear target must be replayable. A preserve target still needs idempotent adapters and application-owned verification. Live handlers must derive time-dependent values from recorded event data, not `NOW()`, randomness, network calls, or ambient process state. Keep external side effects out of replay adapters.

## Rebuild a whole dependency group behind one fence

Drive rebuilds from `ProjectionCatalogOperations`; never accept caller-supplied target, source, handler, subscription, or dedup lists.

1. Preview the catalog-derived group and its destructive disposition.
2. Fence the group and capture one immutable Kiroku head.
3. Clear every declared clear target with one foreign-key-compatible multi-table `TRUNCATE` without `CASCADE`; preserve reconcile targets; reset only the catalog's replayable subscription and dedup identities.
4. K-way merge category sources by global position and apply bounded pages through the catalog's total replay adapters.
5. Persist source cursors, adapter counts, the replay-contract identity, and structured failure evidence after every committed chunk.
6. Run every declared verification. Promote atomically only after all sources prove exhaustion through the captured head and all adapters and verifications complete.

Resume the same run after repairing an application-owned failure. A failed or explicitly abandoned run remains fenced and records durable evidence. Do not expose partial targets merely because an operator chose to abandon the attempt.

The group lifecycle is an offline rebuild, not a shadow-table swap. Keiro never creates, migrates, or swaps application-owned tables; an online cutover remains application-owned.

## Related Patterns

- [Read models and projections](read-models-and-projections.md)
- [Runtime assembly](runtime-assembly.md)
- [Keiro operations console](operations-console.md)
- [Mapped consumer surfaces](mapped-consumer-surfaces.md)
- [Kiroku durable checkpoint inventory](../kiroku/checkpoint-inventory.md)
