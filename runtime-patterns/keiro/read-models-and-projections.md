---
type: Standard
title: "Read models and projections"
description: "Truthful read-model freshness, guarded external SQL contracts, catalog-backed projection application, targeted repair, and snapshot limits"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
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

This standard governs projection ownership, registration, freshness waits, asynchronous fencing, rebuilds, targeted repair, and the one condition that makes snapshots load-bearing.

## Declare one read-side inventory

Every service must build and validate one `ProjectionCatalog`, then use the resulting `ValidatedProjectionCatalog` for registration, live projection selection, rebuilds, and operator inventory. The catalog keeps query-model bindings, physical targets, rebuild groups, owners, source identities, and reset and replay policies explicit.

The full closed-world validation and group-rebuild rules live in [typed projection catalogs and rebuild groups](projection-catalogs.md). [Language 5](language-versions.md) generates the catalog facade, mapped query aliases, and bounded all-row external-read declarations; a hand-written catalog remains the supported bridge for a service still on an earlier language contract. Keyed external reads remain an application-owned catalog extension because their private indexed SQL is not part of the DSL.

## Register before serving queries

Call `registerProjectionCatalog` once during projection startup, before any query call or projection worker. Refuse startup on validation or fingerprint drift. An unregistered query returns `ReadModelUnregistered`; a stale version or `shapeHash` requires a rebuild.

## Declare freshness truthfully, and only where a cursor exists

Define every model through `ReadModelBlueprint` and the truthful builders, never by constructing the record directly. The builder is the place the cursor question is settled:

- `immediateReadModel` with `NoQueryCursor` for a model that is only ever read as it stands;
- `immediateReadModel` or `headWaitingReadModel` with `DurableQueryCursor <subscription>` when a durable cursor exists;
- `positionWaitingReadModel` for read-your-write against a caller-supplied position.

`runQueryWithFreshness` checks registration and liveness, then honours the requested `QueryFreshness`:

- `Immediate` executes without polling;
- `WaitForHead scope` captures one **visible** whole-store (`EntireVisibleLog`) or category (`CategoryVisibleHead`) head and waits for the model's durable cursor to reach it;
- `WaitForPosition` waits for a concrete caller-supplied `GlobalPosition`.

Both waiting modes require `DurableQueryCursor`. A cursorless model fails fast with `ReadModelMissingCursor` on **every** public wait path — including `waitFor` and the deprecated waiting overrides — instead of polling a sentinel for the full timeout and recording a spurious `keiro.projection.wait.timeouts` increment. A position wait that omits its target fails with its own typed error before polling.

Waiting targets the newest visible event, not Kiroku's authoritative append counter, so a caught-up query no longer times out after workflow garbage collection hard-deletes the newest journal events. Projection position distance uses the same reachable head and returns zero when no visible work remains. See [Kiroku append and read](../kiroku/append-and-read.md).

`ConsistencyMode` (`Strong`, `Eventual`, `PositionWait`), the direct waiting fields, and `runQueryWith` are deprecated 0.12 compatibility and are **removed in 0.13**. Migrate now; `runQuery` continues to apply the model's declared default freshness. Under Language 5 the specification carries the same separation: a projection owner declares `delivery`, a read model declares `freshness`, and generated code constructs only through the truthful builders, deriving cursor authority from the validated projection owner. Validation rejects a waiting query with zero or several compatible durable cursors before generation.

## Choose inline or asynchronous application

Use `runCommandWithCatalogProjections` for state the command side must update atomically with its events. It derives the handlers and rebuild-group locks from the validated catalog; projection failure or a fenced group aborts the append transaction.

Use `applyAsyncProjectionFromCatalog` in subscription workers. Its `AsyncApplyOutcome` is part of the checkpoint protocol: acknowledge `AsyncApplied` and `AsyncDuplicate`; on `AsyncFenced`, do not checkpoint past the event—fail or park it until the group is live.

Each path dispatches only the revision handler bound to its own delivery capability. A revision may change the SQL behind a projection; it must never turn a subscription-delivered effect into command-time work or the reverse. See [typed projection catalogs and rebuild groups](projection-catalogs.md).

Handlers must derive time-dependent values from recorded event time or payload data. `NOW()`, wall-clock reads, random values, network calls, and other ambient effects make replay diverge from the live result. Keep external side effects out of replay adapters.

## Choose the offline or online group lifecycle

Drive rebuilds through `ProjectionCatalogOperations`, never caller-supplied table, subscription, or projection lists. Fence the complete dependency group, capture one immutable event-store head, replay deterministic bounded pages, persist resumable evidence, run every declared verification, and promote only when all sources prove exhaustion. A failed or abandoned run stays fenced.

Use the offline lifecycle for in-place reconstruction when planned unavailability is acceptable. It fences readers and writers, clears or preserves each serving target according to catalog policy, and returns the group to service only after replay and verification.

Use the schema-versioned lifecycle when V1 must keep serving while an incompatible V2 schema is built. Deploy both executable `ProjectionRevision` values in the same validated catalog. Application-owned `TargetProvisioner` closures create and validate complete staging schemas under Keiro-allocated names; Keiro owns durable generations, source retention, converging replay, the bounded final writer/table-lock phase, async deduplication and checkpoint reconciliation, atomic all-target promotion, and retirement. Live writers select the persisted serving revision and complete physical-target map under the group lock, and fail closed when the running binary lacks that revision.

The restricted clone mode is only for exact-shape repair and refuses unsupported PostgreSQL DDL and dependencies. It is not the schema-evolution mechanism. A retained V1 generation stops receiving writes after promotion: treat it as forensic or drain evidence, not an automatically current compatibility or rollback surface. Preview/drop must refuse active runs, compatible read contracts, and ordinary PostgreSQL dependencies.

Kiroku's renewable history-retention lease protects the active replay from hard deletion, and refuses direct destructive SQL while it is held. An expired or unrenewable lease invalidates the old candidate; abandon and restart rather than acquiring a new lease and guessing that history stayed unchanged. See [Kiroku replay-history retention](../kiroku/history-retention.md).

Neither lifecycle is the tool for one damaged stream. When a projection declares a `StreamScopedReplay` policy, repair that stream in place under [targeted stream-scoped projection repair](stream-scoped-repair.md) instead of fencing the whole group.

Preview and operate both lifecycles through the mounted [Keiro operations console](operations-console.md). The architecture is governed by `mori://shinzui/keiro/okf/adrs/concepts/ADR-34` and implemented under `mori://shinzui/keiro/masterplans/41-make-read-models-safely-readable-by-out-of-process-consumers`.

## Publish external reads only through the guarded SQL surface

Never grant an out-of-process reader `SELECT` on a projection table, serving-name alias, retained generation, or Keiro private binding. A separate status check followed by a raw read races both offline fencing and online promotion. A retained generation is especially dangerous because it stays readable after it stops receiving writes.

Declare a versioned `ExternalReadContract` in the validated catalog. Keiro publishes an execute-only security-definer function named `keiro_read.<contract>_v<version>`. Its outer guard takes the rebuild-group lifecycle lock `FOR SHARE`, then checks `reads_allowed`, contract state, serving revision, and result shape before invoking the private binding in the same transaction. The external client must use an ordinary read-write PostgreSQL transaction; read-only transactions cannot take this lock.

Treat the application-owned composite result type as the public row ABI. The bounded all-row form selects exactly that type's ordered attributes, so a new physical column does not silently widen V1. The wrapper enforces the bound itself: an all-row read returning more than 100 rows raises `KR004` with the contract, version, and limit in its detail. Design an all-row contract for a genuinely small projection rather than treating that ceiling as a page size.

For high-cardinality access, provide a versioned private keyed function with typed arguments and indexes; Keiro wraps and guards it but never grants the consumer access to it. Reconciliation verifies that the private implementation exists **and** returns a set of exactly the declared composite result type, so a signature-compatible function with the wrong row type is refused at registration instead of at read time.

Grant the consumer only `USAGE` on `keiro_read` and the contract-type schema, `USAGE` on the result composite type, and `EXECUTE` on the selected wrapper. Grant no access to `keiro`, `kiroku`, the application projection schema, the private implementation schema, the shared guard, or generated private bindings. Deployment owns roles and grants; Keiro revokes `PUBLIC` execution from managed and private functions.

Handle the stable SQLSTATEs as a closed operational contract: retry `KR001` with bounded backoff; treat `KR002` as an unknown or retired contract; migrate or deploy an explicit compatibility implementation for `KR003`, which means the serving revision or result shape is incompatible; and treat `KR004` as a contract-design error, not a transient condition. Do not branch on message text.

`KR001` covers two retryable conditions. The group may be fenced, or a promotion may have committed while this read waited on the lifecycle lock: PostgreSQL fixed the caller's statement snapshot before the wrapper ran, so the guard refuses a crossed serving epoch rather than serving the old snapshot's catalog and relations. Both mean "issue a new statement", which is why the client must retry rather than reuse the same statement's transaction snapshot. Kiroku raises the same `KR001` code for an unrelated retention condition; classify by the function you called. See [Kiroku replay-history retention](../kiroku/history-retention.md).

During candidate replay, V1 remains bound to the serving generation. Promotion atomically rebinds an additive compatible version and activates a new breaking version. An incompatible old wrapper remains present but fails `KR003`; preserving its retired table does not preserve current reads. Keep V1 current only through an explicit implementation-backed compatibility contract that reads the new serving data while retaining the old public signature.

Inspect with `rebuild external-read CONTRACT VERSION`. Retirement is a separate preview/force operation, `rebuild retire-external-read CONTRACT VERSION`, that reports PostgreSQL dependents and the `EXECUTE` grants **of the selected overload only** before marking the managed surface retired — a same-named wrapper at another version or argument list is not reported as this contract's exposure. Retiring a contract does not drop a retained target generation, and dropping a generation does not retire a public contract.

This privilege and locking boundary is fixed by `mori://shinzui/keiro/okf/adrs/concepts/ADR-36` and implemented by `mori://shinzui/keiro/plans/255-fence-out-of-process-read-model-reads-behind-a-sanctioned-sql-surface`.

## Keep snapshots advisory—with one exception

The glossary rule is normative: snapshots accelerate hydration but do not define aggregate truth while the complete replayable prefix remains in the event store. Missing, corrupt, or shape-mismatched snapshots fall back to full replay.

The exception is history truncation. Once Kiroku hides a per-stream prefix, a valid snapshot must cover that prefix; deleting it produces `HydrationGapDetected`. Restore visibility with the store's truncation controls or install a covering snapshot before resuming commands.

Prove coverage before creating the gap rather than diagnosing it afterwards. `snapshot truncation-preflight --before VERSION` in the [operations console](operations-console.md) checks the advisory snapshot row against a proposed truncate marker; pass the current `--state-codec-version`, `--regfile-shape-hash`, and `--state-shape-hash` so it answers for the codec actually deployed. Moving a marker without that check is how a stream becomes unhydratable in production.

Async projection dedup rows have their own retention decision. `projection prune-dedup --projection NAME --before UTC` deletes redelivery-safety evidence: choose a cutoff older than the longest redelivery window that can still reach the projection, and never prune while its group has an active rebuild.

## Match all three snapshot discriminator components

An aggregate snapshot is loaded only when three independent components agree:

1. `stateCodecVersion`, owned manually by the service;
2. `shapeHash`, the register-layout identity;
3. `stateShapeHash`, the control-state and replay-fold identity.

`defaultStateCodec` derives the third through keiki's `CanonicalStateShape`, so register-layout and control-state changes invalidate stale seeds automatically. Generated codecs compose a spec-derived fold fingerprint as `<state-hash>;fold=<fingerprint>` through `withFoldFingerprint`; hand-written services may supply and maintain their own token the same way.

The manual clause is still load-bearing. **A fold or guard change the derivation cannot see — hand-written update logic, or logic living only in a generated service's hand-owned Holes module — must bump `stateCodecVersion`.** Nothing else will catch it: an unbumped invisible change presents identical discriminators by construction. As a backstop, one accepted seed in 1000 is verified against a full replay, and a mismatch increments `keiro.snapshot.seed.divergence`; alert on that metric.

Rows written before the discriminator gained its third component carry an empty sentinel. They miss once, full-replay, and may then be replaced with a current seed, so expect a one-time replay cost per stream after the upgrade.

Keiro 0.9 widened the fold fingerprint from a 16-hex-digit FNV-1a-64 to a 32-hex-digit FNV-1a-128 value. The widening is deliberate and invalidates every snapshot discriminated by the earlier token: after the upgrade each stream misses once and rebuilds from events. Plan the replay cost and refresh generated transducers; do not attempt to translate old tokens. Read-model, mapped-wire, and behavior-key identities are separate 64-bit values and did not move.

For depth, consult `mori://shinzui/keiro` at project-relative paths `docs/user/read-models-and-projections.md`, `docs/user/snapshots.md`, `docs/guides/project-read-models.md`, and `docs/guides/online-projection-rebuilds.md`; artifact-level Mori document handles for those repository-local guides are pending.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Typed projection catalogs and rebuild groups](projection-catalogs.md)
- [Targeted stream-scoped projection repair](stream-scoped-repair.md)
- [Kiroku replay-history retention](../kiroku/history-retention.md)
- [Mapped consumer surfaces](mapped-consumer-surfaces.md)
- [Keiro operations console](operations-console.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [The two-schema arrangement](two-schema-arrangement.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
