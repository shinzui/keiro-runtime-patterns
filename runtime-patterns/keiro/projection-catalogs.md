---
type: Standard
title: "Typed projection catalogs and rebuild groups"
description: "One validated projection inventory, guarded external read contracts, delivery-bound revision writers, and deterministic rebuilds"
timestamp: 2026-10-14T22:01:17Z
generated:
  by: process:codex
  at: "2026-10-14T22:01:17Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-projection-catalogs
tags: [keiro, projection-catalogs]
status: current
---

# Typed projection catalogs and rebuild groups

**Build one closed-world `ProjectionCatalog`, validate it once, and derive every live writer and rebuild action from that same value.**

Use this read-side baseline with the released Keiro 0.21.0.0 cohort. Its design is fixed by `mori://shinzui/keiro/masterplans/32-build-typed-projection-catalogs-and-safe-coordinated-rebuilds` and the checkpoint-lifecycle follow-up `mori://shinzui/keiro/masterplans/33-make-subscription-checkpoint-lifecycle-explicit-before-the-next-release`.

## Keep every identity explicit

The catalog must declare all of these separately:

- a typed query-model binding for what an application query observes;
- a physical target for one application-owned table and its reset policy;
- a rebuild group for targets that fence, prepare, verify, and promote together;
- a projection owner for one source, its ordered handlers, owned targets, and replay policy;
- every asynchronous subscription and deduplication identity used by those handlers;
- every executable projection revision, including per-target schema/provisioner/validator identity, delivery-bound live handlers, replay adapters, verification, ordered canonical promotion-object names, and any stream-scoped repair policy; and
- every versioned external-read contract, including query binding, stable composite result type and shape, compatible revisions, surface generation, and any typed private keyed implementation.

Validation must reject duplicate ownership, unresolved references, cross-group ownership, dependency cycles, wrong handler order, and a clear-before-replay target with no replayable owner. Persist and compare the inventory so removing a target and its owner together cannot disappear as an apparently clean startup. Inventory application SQL and external writers separately; catalog validation is closed-world only over what the application declares.

[Language 5](language-versions.md) generates the catalog facade and create-once handler holes. A hand-written catalog is the bridge for earlier language contracts; unmanaged wrappers are migration aids, not the new-service baseline.

Validate the catalog once at startup and share that one `ValidatedProjectionCatalog` value. It carries the precomputed revision, delivery, and async-registration indexes the command and subscription paths use, so rebuilding or revalidating it per command is a measurable cost on the hot path, not a stylistic choice.

## Register before any reader or writer starts

Call `registerProjectionCatalog` once after migrations, result-type and private-function deployment, and catalog validation, before queries, command-side projection writes, asynchronous workers, or external SQL traffic. Refuse startup on validation failure, catalog-fingerprint drift, incompatible registered query metadata, or external-contract reconciliation failure.

Derive typed query registrations, inline projection sets, asynchronous handlers, inventory, and operations from the validated value. Do not keep parallel maps in startup code, workers, or an operations executable.

Default query targets to subscription delivery through `applyAsyncProjectionFromCatalog`, with bounded post-commit position waits when callers need read-your-write. Use `runCommandWithCatalogProjections` only for minimum state required by an explicit atomic invariant. Separate that state from rich query targets using distinct owners and groups where dependencies permit. See [delivery and freshness guidance](read-models-and-projections.md). Treat `CatalogAsyncApplyOutcome` as checkpoint protocol: acknowledge `CatalogAsyncApplied` and `CatalogAsyncDuplicate`; do not checkpoint a `CatalogAsyncFenced` delivery or any invalid catalog/serving-binding outcome past unapplied work.

Once a group adopts schema-versioned generations, the group lock must return its persisted serving revision, monotonically increasing serving epoch, and total physical-target binding as one fact. A missing compiled revision, missing generation, or extra target is a refusal before application SQL; never fall back to an unversioned handler after promotion.

## Bind every live handler to one delivery capability

A revision's live handlers are not an unordered bag applied to everything. Each `RevisionLiveHandler` declares its exact `RevisionLiveDelivery` — inline for one projection and query model, or subscription for one projection, subscription, and dedup identity — and the command and subscription paths dispatch only the closure matching the capability they are executing.

Validation requires exactly one handler per declared capability and restricts that handler's required targets to its supplying projection's owned targets, reporting `ProjectionRevisionLiveCapabilityMismatch` and `ProjectionRevisionLiveTargetOwnershipMismatch` otherwise. This is what keeps revision selection a change of physical SQL: a new revision must not promote a subscription-delivered effect into command-time work, demote command-time work into a subscription, or reach a target its projection does not own. The canonical identity carrying these facts is `catalog-v7:` and `slice-v6:`.

## Make external read contracts catalog identity

An external SQL reader must never receive raw projection-table privilege. Declare an `ExternalReadContract` whose identity and positive version form `keiro_read.<contract>_v<version>`. The declaration binds one query model to a stable application-owned composite result type, result-shape hash, compatible projection revisions, and monotonic surface generation. A keyed contract also declares its typed arguments and versioned private implementation function.

Catalog validation rejects unresolved query or revision references, invalid SQL identities, duplicate public signatures, invalid result or implementation facts, and incompatible immutable declarations. Catalog and group-slice fingerprints include every contract fact, so a rolling process cannot silently downgrade or redefine an existing surface.

Registration and reviewed adoption reconcile the serving-compatible surface transactionally. Keiro verifies that the result type exists and is composite, verifies a keyed implementation's argument signature, persists candidate metadata without prematurely installing its wrapper, and reconciles managed objects individually rather than recreating `keiro_read`. The public wrapper holds the group lifecycle row `FOR SHARE` while checking availability and compatibility and then reading the private binding. This makes the authorization decision and data read one lock-coupled operation.

All-row contracts are intentionally bounded — the wrapper raises `KR004` above 100 rows — and high-cardinality access uses an application-owned keyed implementation whose declared composite set-result type is verified at reconciliation. The consumer receives only the public wrapper and result-type privileges, and a retirement preview reports the execute grants of the selected overload alone. Stable `KR001`, `KR002`, `KR003`, and `KR004` SQLSTATEs distinguish retryable unavailability (including a promotion that crossed this statement's snapshot), unknown or retired contracts, serving incompatibility, and an over-limit all-row read. See [read models and projections](read-models-and-projections.md) for client transaction, grant, versioning, and error-handling rules.

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

This in-place protocol is the offline lifecycle. It remains appropriate when planned unavailability is acceptable or preservation policies require reconstruction in the serving tables.

## Rebuild an incompatible schema beside the serving revision

For online schema evolution, keep both serving and candidate `ProjectionRevision` values in the catalog and use the dedicated versioned operations protocol.

1. Begin allocates one deterministic staging generation per target, acquires Kiroku history retention, invokes each application `TargetProvisioner`, and reconciles the serving-compatible external contracts in the metadata transaction. Failed DDL, validation, or contract reconciliation rolls back every candidate object and lease.
2. Replay uses the candidate revision and its total physical-target map while live inline and async writers continue through the persisted serving revision.
3. Resume converges in bounded pages. Near the head, Keiro fences writers, captures a durable final head, and replays to it without exposing staging names.
4. Candidate verification, set-based dedup installation, checkpoint reconciliation, and lease release complete in a resumable preparation phase **before** any target relation is locked, and async redelivery evidence is staged incrementally in PostgreSQL and admitted against a persisted operator limit.
5. Promotion then acquires every serving and staging relation in one cumulative lock statement under an absolute database-clock deadline, revalidates relation OIDs and schema/object evidence, renames every target and canonical object, changes the serving revision and epoch, rebinds compatible external wrappers, activates new versions, and retires V1 in one transaction.
6. Writer-fence and promotion lock attempts are bounded by that deadline and fail with typed phase-specific errors naming the phase that ran out of time. A lock timeout or DDL race rolls the whole promotion back. Repair the owned cause and resume the same stored contract, or abandon staging and restart when retention or identity evidence is no longer trustworthy.

Applications own desired DDL and compatibility meaning. Keiro owns the transaction, generation, replay, fence, promotion, and retirement machinery. `RestrictedClone` is a typed, exact-shape convenience that refuses external `nextval` defaults, foreign keys, triggers, rules, policies/RLS, inheritance or partitioning, publications, non-default ownership/ACL or replica identity, and unmodelled dependencies. Use `ApplicationProvisioned` for a changed schema.

Retired generations no longer receive live writes and are not rollback-ready merely because they still exist. List them for inspection, then use the supported preview/force drop. The preview must account for active runs, compatible read contracts, and ordinary PostgreSQL dependencies; final drop rechecks under an exclusive lock and never uses `CASCADE`. Retire public contract versions separately through the supported dependency-and-grant preview; contract retirement marks the guarded surface unavailable and never implies generation destruction.

The generation boundary is fixed by `mori://shinzui/keiro/okf/adrs/concepts/ADR-34` and `mori://shinzui/keiro/plans/256-rebuild-into-versioned-targets-with-atomic-cutover`. The external-read privilege and compatibility boundary is fixed by `mori://shinzui/keiro/okf/adrs/concepts/ADR-36` and `mori://shinzui/keiro/plans/255-fence-out-of-process-read-model-reads-behind-a-sanctioned-sql-surface`.

## Repair one stream without fencing the group

A revision may additionally declare a `StreamScopedReplay` policy per projection: the projection's exact owned targets, a stream-row clearer, a per-event replay closure, a verification, and the async dedup identities it affects. Validation rejects a duplicate, cross-group, unknown-projection, target-mismatched, dedup-mismatched, or unversioned policy.

That declaration is what makes one stream's rows repairable in place against the persisted serving revision, under an admission limit and without moving subscription checkpoints. It is not a replacement for either group lifecycle; see [targeted stream-scoped projection repair](stream-scoped-repair.md).

## Check relational command preconditions under the catalog fence

Use `runDomainCommandWithCatalogProjectionsGuarded` for the minimal synchronous relational authority a command invariant needs. The runner tentatively appends, resolves all required catalog group fences and serving bindings, then calls `CatalogPreconditionContext -> Tx.Transaction (Either refusal ())`. `Left` returns `PreconditionRefused` after full rollback; `Right ()` applies inline handlers using those exact protected bindings. Silent domain rejection/no-op invokes neither catalog SQL nor the callback, and a refused append supplies no committed receipt or position.

Read `catalogPreconditionBindings` only inside the callback. Retaining the value retains no lock. Keep checks bounded, indexed and transaction-local; no network effects, recursive append, extra stream/group locks, transaction/savepoint/isolation control, `Tx.condemn`, sequences, session locks or effects that survive rollback. Hasql may rerun the callback; `RunCommandOptions.retryLimit` bounds OCC retries, not the driver's transaction retry loop.

Atomic identity checks rely on every participating writer using synchronous authority in the same Kiroku store and its global append lock under ReadCommitted. An asynchronous target, arbitrary external SQL writer, or missed creation path invalidates that guarantee. The callback sees its own tentative append, not proof it won. Test concurrent connections and rich-view workers paused; keep the guard minimal because it extends the store-wide append lock. Correctness is validated, but deferred exhaustive performance gates are not a throughput guarantee.

## Related Patterns

- [Read models and projections](read-models-and-projections.md)
- [Targeted stream-scoped projection repair](stream-scoped-repair.md)
- [Kiroku replay-history retention](../kiroku/history-retention.md)
- [Runtime assembly](runtime-assembly.md)
- [Keiro operations console](operations-console.md)
- [Mapped consumer surfaces](mapped-consumer-surfaces.md)
- [Kiroku durable checkpoint inventory](../kiroku/checkpoint-inventory.md)
