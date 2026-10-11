---
type: Standard
title: "Read models and projections"
description: "Truthful read-model freshness, guarded external SQL contracts, catalog-backed projection application, targeted repair, and snapshot limits"
timestamp: 2026-10-11T21:13:17Z
generated:
  by: process:codex-cli
  at: "2026-10-11T21:13:17Z"
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

**Default query models to asynchronous delivery, wait after commit for read-your-write, and keep only minimum atomic invariant state synchronous. Register queries and apply projections through the validated catalog; snapshots remain advisory until history is truncated.**

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

`ConsistencyMode` (`Strong`, `Eventual`, `PositionWait`), the direct waiting fields, and `runQueryWith` remain exported but deprecated in 0.17.0.0. They stay only because published Language 4 read-model generation still emits them, and are removed together with that frozen generator in a later major release. Do not write new code against them; migrate to the truthful freshness builders and `runQueryWithFreshness`. `runQuery` continues to apply the model's declared default freshness. Under Language 5 the specification carries the same separation: a projection owner declares `delivery`, a read model declares `freshness`, and generated code constructs only through the truthful builders, deriving cursor authority from the validated projection owner. Validation rejects a waiting query with zero or several compatible durable cursors before generation.

## Choose inline or asynchronous application

Use `applyAsyncProjectionFromCatalog` in subscription workers for query models by default, including aggregate-local views. Its `CatalogAsyncApplyOutcome` is part of the checkpoint protocol: acknowledge `CatalogAsyncApplied` and `CatalogAsyncDuplicate`; on `CatalogAsyncFenced`, do not checkpoint past the event—fail or park it until the group is live. Unregistered groups, unknown projections, unavailable serving revisions, and invalid serving bindings also require repair without acknowledging unapplied work. The application owns worker startup and supervision.

Use `runCommandWithCatalogProjections` only for minimum state a specified invariant requires to commit atomically with its events. It derives handlers and rebuild-group locks from the validated catalog; projection failure or a fenced group aborts the append transaction. Immediate reader convenience alone does not justify inline delivery. Reactor `targetProjections` should default to empty; those compatibility hooks do not acquire catalog rebuild fences.

Kiroku holds its global `$all` row lock until append transaction end. Every inline handler or post-append guard extends that interval and can delay unrelated writers in the same store. Keep SQL bounded, indexed, and local. Never poll subscriptions, make network calls, or perform unbounded work inside the transaction. Measure cumulative inline work, mixed-traffic throughput, and ordinary-writer p95/p99 latency. Async workers still share database capacity; removing work from the append transaction does not eliminate all contention.

Each path dispatches only the revision handler bound to its own delivery capability. A revision may change the SQL behind a projection; it must never turn a subscription-delivered effect into command-time work or the reverse. See [typed projection catalogs and rebuild groups](projection-catalogs.md).

Handlers must derive time-dependent values from recorded event time or payload data. `NOW()`, wall-clock reads, random values, network calls, and other ambient effects make replay diverge from the live result. Keep external side effects out of replay adapters.

## Return acceptance, then wait for the view

Return the command result directly when it contains what the caller needs. Otherwise, after confirmed command completion, use `runQueryWithFreshness` with `WaitForPosition (defaultHeadWaitOptions { target = Just position, timeoutMicros = 500000, pollMicros = 10000 })`, where `position` is the successful `CommandResult.globalPosition` and the timeout is an application budget, not a universal default.

A compatible `DurableQueryCursor` and a supervised subscription worker are prerequisites. A cursor is trustworthy only if required events cannot be checkpointed without applying the projection. Return **committed, view pending** on `ReadModelWaitTimeout`, retain the receipt, and retry the query/wait without resubmitting the command. Registration, shape, cursor, and liveness errors mean view unavailable and require separate diagnosis. Store/transport errors after a confirmed commit also do not undo it; preserve command commit uncertainty when confirmation was never obtained.

A silent no-op or rolled-back refusal has no new committed position. Return its decision or canonical identity; use a retained winning receipt only when one exists, never the losing candidate's tentative position. A position wait proves a known progress boundary, not an atomic command-and-query operation or freshness against future writes. The handler fragment is in [Keiro's async guide](mori://shinzui/keiro/okf/guides/concepts/DOC-6).

## Separate identity authority from rich query models

For ensure/reuse across candidate aggregate IDs, the minimal synchronous index maps `(anchor type, anchor ID, property definition ID, state ID)` to the winning note ID. Keep content, tags, display joins, search, and reporting in asynchronous targets. Retain mappings across archive if reuse is the business rule; define deletion, re-anchoring, legacy migration, and replay explicitly. Only add synchronous receipt metadata when the caller contract actually needs it. Every live writer that changes the identity must participate in one proven serialization protocol; a synchronous index alone does not close a check/write race.

Declare separate owners and rebuild groups where dependencies permit independent lifecycles. Do not give the identity row a foreign key to a rich-view row that may not yet exist, or bypass real dependencies to force separation. The identity index is command authority even though it is event-derived: fail closed while it is unavailable and never substitute a lagging view. Prove ensure/reuse with the rich-view worker paused, then verify one original payload after catch-up; also test independent group fencing, replay, and concurrent connections in one database.

The public composition for a typed relational guard plus catalog delivery is **planned**, under [Keiro ExecPlan 306](mori://shinzui/keiro/plans/306-support-atomic-relational-preconditions-for-synchronous-catalog-commands) and [IR-53](mori://shinzui/keiro/okf/improvement-requests/concepts/IR-53). It is not a released API. Do not call the proposed symbol, copy private catalog SQL, or use pre-command SELECT followed by append as a uniqueness guarantee. Keep unsafe writes disabled until a supported proven protocol is available; adopt only after verifying the actual dependency release and its contract.

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
