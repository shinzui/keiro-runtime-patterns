---
type: Pattern
title: "Checked Composition"
description: "Wiring transducers with composeChecked, alternative, and the feedback1 stateless-only trap"
timestamp: 2026-07-22T09:39:08-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-checked-composition
tags: [keiki, checked-composition]
status: current
---

# Checked Composition

**Check every transducer boundary before treating a composed machine as one durable consistency boundary.**

Keiki can combine transducers sequentially, by disjoint choice, or through a deliberately narrow one-round cascade. Prefer `composeChecked` for aggregate-to-policy pipelines, understand the poison guard around non-invertible maps, and keep independently identified aggregates on separate runtime streams.

## Prefer `composeChecked` At Every Sequential Boundary

`compose` is the unchecked construction primitive: it feeds the first transducer's output alphabet into the second transducer's input alphabet. `composeChecked` first runs `checkComposeAlignment` and returns every structural warning instead of constructing a suspicious pipeline.

```haskell
case composeChecked aggregateTransducer policyTransducer of
  Right pipeline -> usePipeline pipeline
  Left warnings -> reportAlignmentWarnings warnings
```

`ComposeAlignmentWarning` reports four boundary facts with source locations:

- `UnconsumedWireOutput` means an upstream wire constructor has no consuming downstream edge at a reachable vertex.
- `UnmatchedInCtorExpectation` means a downstream input-constructor expectation has no upstream emission.
- `FieldArityMismatch` means a downstream field read addresses a position the upstream constructor does not emit.
- `PoisonedNameInComposition` means a mapped or otherwise poisoned constructor name reached the boundary.

The reachability scan is conservative. Every warning is reviewable evidence of a name or position mismatch, but an empty list is not a proof about opaque guard logic. Keep `validateTransducer` on the resulting machine as a separate replay and determinism gate.

## Do Not Compose Across A Non-Invertible Map

`SomeSymTransducer` in `Keiki.Profunctor` carries input and output poison provenance. `lmap`, `rmap`, and `dimap` can preserve forward evaluation while destroying the inverse information replay needs; their rewritten constructor names are stamped with `#lmapped` or `#rmapped`.

Categorical composition checks that provenance. Crossing a poisoned upstream output or downstream input raises `PoisonedCompositionError` synchronously instead of silently bypassing a map or producing a dead pipeline. Move the map outside the composition boundary, or author a structural transducer whose input and wire constructors have honest `icBuild` and `wcMatch` behavior.

## Use `alternative` Only Inside One Consistency Boundary

`alternative left right` builds one transducer over `Either ci1 ci2` and emits `Either co1 co2`. Each command advances only its selected arm, while the composite vertex and register file retain both arms. `PLeftArm` and `PRightArm` make the two arms disjoint in both concrete and symbolic evaluation even when an underlying guard is `PTop`.

This is appropriate for two machines that intentionally share one durable identity, version check, append, and replay lifecycle. It is not a router for sibling aggregates. If each arm needs its own stream identity, optimistic-concurrency version, snapshots, or independent retention, keep separate keiro event streams and route at the runtime layer.

## Treat `feedback1` As A Two-Copy Cascade

`feedback1` is not shared-state aggregate feedback. Its definition is a single round with two copies of the aggregate-shaped transducer:

```haskell
feedback1 t f = compose t (compose f t)
```

The outer copy consumes the external command and emits an event. The policy consumes that event and emits a follow-up command. The inner aggregate copy consumes the follow-up and produces the composite output. Its vertex is `Composite s1 (Composite s2 s1)`, so the policy-produced command updates the inner copy—not the state that handled the original command.

The constraint `Disjoint (Names rs1) (Names (Append rs2 rs1))` can be satisfied only when `rs1` is empty, because the aggregate register names occur on both sides. One call therefore requires a stateless aggregate copy. Nesting another round also forces the policy register file `rs2` to be empty. There is deliberately no `feedback1Checked`; alignment checks cannot turn two distinct state copies into shared state.

Use `feedback1` only when that precise stateless, one-round contract is wanted. Hosted process managers with durable saga state, dispatch, and timers belong to keiro rather than this combinator.

## Preserve The 0.2 Update Semantics

Within one edge, `UCombine` has snapshot or parallel-assignment semantics: every right-hand side reads the register file as it existed at edge entry, then writes are applied left-to-right. Do not write a later update expecting it to observe an earlier write from the same edge.

Sequential `compose` has a different responsibility across machines. When one upstream edge emits several events, composition symbolically threads the downstream machine's earlier register writes into its later guards, updates, and outputs before collapsing the path. This makes the composite agree with stepping the downstream transducer event by event.

## Keep The Orchestrator Boundary Honest

In keiki an orchestrator is a transducer, so `composeChecked` can validate a pure aggregate-to-policy boundary. The hosted `ProcessManager` abstraction—with correlation, its own saga stream, target dispatch, idempotency, and timers—belongs to keiro. The complete runtime pattern is tracked by [EP-5](https://github.com/shinzui/keiro-runtime-patterns/blob/master/docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md).

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) places composition in the full authoring workflow.
- [Build-Time Validation](./build-time-validation.md) checks the replay and determinism contract after composition.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) explains the inverse information that poison provenance protects.
- [Collections and Opaque Guards](./collections-and-opaque-guards.md) gives another reason to split independently identified sub-entities into separate streams.
