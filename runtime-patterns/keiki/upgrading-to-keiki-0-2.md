---
type: Guide
title: "Upgrading to Keiki 0.2"
description: "Migration notes for keiki 0.2: noEmit, new validation warnings, snapshot-hash change, Decider removal"
timestamp: 2026-07-22T09:39:08-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-upgrading-to-keiki-0-2
tags: [keiki, upgrading-to-keiki-0-2]
status: current
---

# Upgrading to Keiki 0.2

**Migrate in compiler, CI, operational, and solver order so every 0.2 change fails in the most useful place.**

Keiki 0.2.0.0 is a hardening release. It makes builder intent explicit, expands replay-safety validation, introduces structured hydration diagnostics and event-codec evolution, changes non-empty register shape hashes once, and removes the pre-release Decider facade. Apply the following sequence to each 0.1 service.

## Fix Compile-Time Breakage First

Every `onCmd` and `onEpsilon` builder body must now declare output intent with `emit`, `emitWith`, or `noEmit`. A body that previously fell through to `goto` and silently became an output-free edge now fails eager builder validation.

```haskell
-- Before 0.2: silently created an output-free edge.
B.onCmd inCtorAcknowledge $ \_ -> B.do
  B.goto Acknowledged

-- After 0.2: state the deliberate intent.
B.onCmd inCtorAcknowledge $ \_ -> B.do
  B.noEmit
  B.goto Acknowledged
```

Use `buildTransducerEither` when a test or CLI should receive every located `BuilderError` instead of letting `buildTransducer` render and throw. Both builders require `DistinctNames (Names rs)` and `Eq v`; `buildTransducer` also needs `Show v` for its error text. Duplicate slot names are now compile-time errors, and the old `Bounded v` and `Enum v` builder constraints are gone.

Code that exhaustively matches `TransducerValidationWarning` must add `HeadUnrecoverable`, `InversionAmbiguity`, `UnguardedInputRead`, and `StateChangingEpsilon`. Code that constructs `ValidationOptions` should switch to record updates on `defaultValidationOptions`.

The `keiki-codec-json` event splice now emits a fifth binding, `<prefix>SchemaVersion :: Int`. `EventCodecOptions` has four additional fields—`kindOverrides`, `versionFieldName`, `currentVersion`, and `upcasters`—and `FieldCodec` adds `fcOnMissing`. Update positional construction to named record updates from the defaults.

## Repair New Startup And CI Warnings

A transducer that passed 0.1 validation may now report one of four replay-safety defects:

- `HeadUnrecoverable`: a multi-event edge puts a consumed field only in a tail event.
- `InversionAmbiguity`: two outgoing edges share the same head wire constructor.
- `UnguardedInputRead`: an input field read lacks the matching constructor guard.
- `StateChangingEpsilon`: an output-free edge changes the control vertex or registers.

These are true positives. Repair the transducer rather than pinning old options. Keiro's `mkEventStream` rejects a stream on any warning and force-enables head recoverability and state-changing-epsilon checks at its durable boundary.

## Expect One Snapshot Cache Miss Per Stream

Built-in `CanonicalTypeName` instances now use pinned, module-independent names such as `Int`, `Text`, and `Maybe(Int)`. Every non-empty register-file shape hash therefore changes once when moving from 0.1 to 0.2.

Keiro snapshot stores compare the stored hash with `regFileShapeHash`. An old hash becomes a benign cache miss: the runtime replays the complete event log and can write a snapshot under the new hash. Plan for one slower hydration per stream after deployment; do not rewrite or trust old snapshots under a new discriminator.

Container instances now recurse through `CanonicalTypeName`. A custom type used inside `Maybe`, a list, `Either`, or a tuple may need `deriving anyclass (CanonicalTypeName)`, or an explicit stable name when its module path is not a durable identity. Missing evidence is a compile error, not silent hash drift.

## Replace The Removed Decider Facade

The lossy pre-release Decider API is gone. Use `stepEither` for forward command decisions and the structured replay functions for hydration:

```haskell
forwardResult = stepEither orderTransducer (state, regs) command
hydratedResult = reconstituteEither orderTransducer storedEvents
```

For paged replay use `replayEvents`; for a complete caller-supplied chunk use `applyEventsEither`; for one observed event use `applyEventStreamingEither`. The older `Maybe` wrappers remain only for compatibility. There is no letter-only facade that silently retains the input state after replay failure.

## Recheck Solver-Backed Suites

Solver uncertainty now fails conservatively. `Unknown`, `ProofError`, and every result other than definite unsatisfiability no longer bless two guards as disjoint or an edge as dead. `satResultIsProvablyUnsat` exposes the exact verdict.

This can surface pairs that older suites treated as proved. Simplify the guards, strengthen the test model, or treat the result as unproven; do not convert uncertainty back into success. Platform-sized `Int` remains modeled as unbounded `Integer`, so proofs whose truth depends on overflow should use `Int32`, `Int64`, or a `Word*` type.

## Run The Migration Proof

After compilation succeeds, require `validateTransducer defaultValidationOptions t == []` for every aggregate and orchestrator. Replay historical event fixtures through `reconstituteEither`, run a multi-event truncation case, confirm old event JSON decodes under the configured defaults or upcasters, and observe one full replay when an old snapshot hash is encountered.

The release facts in this guide match keiki `0.2.0.0`, released 2026-07-13 and tagged upstream as `v0.2.0.0`.

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) is the post-migration authoring standard.
- [Build-Time Validation](./build-time-validation.md) documents all eight warning constructors and the solver contract.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) replaces opaque hydration failure with exact diagnostics.
- [Event Schema Evolution](./event-schema-evolution.md) covers the new codec options and compatible evolution moves.
- [Checked Composition](./checked-composition.md) covers the 0.2 alignment and poison-provenance checks.
