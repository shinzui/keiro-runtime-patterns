---
type: Guide
title: "Build-Time Validation of Keiki Transducers"
description: "Asserting transducers and typed field projections are well-formed in CI with validateTransducer"
timestamp: 2026-07-28T19:53:40-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-build-time-validation
tags: [keiki, build-time-validation]
status: current
---

# Build-Time Validation of Keiki Transducers

**Treat every validation warning as a model defect before a durable stream reaches production.**

Keiki can prove important replay and transition properties before any event is stored. Put the pure `validateTransducer` umbrella in every service test suite, understand its structured warnings, and reserve the solver-backed checks for models whose guards fall outside the pure checker's exact fragment.

## Start With `validateTransducer`

`validateTransducer` runs seven configurable default-on checks plus unconditional typed-projection checks over the `HsPred` carrier without starting z3. A well-formed aggregate or orchestrator returns no warnings:

```haskell
import Keiki.Core (defaultValidationOptions, validateTransducer)

-- CORRECT: make the complete default validation contract a CI gate.
validateTransducer defaultValidationOptions incidentTransducer == []
```

The result is `[TransducerValidationWarning s]`, not rendered text. Every warning identifies an edge with the typed `EdgeRef s` locator, or identifies an edge pair by source vertex and declaration indices.

## Keep All Seven Soundness Checks Enabled

`ValidationOptions` has eight fields: seven default-on soundness checks and the opt-in opaque-guard audit.

```haskell
data ValidationOptions = ValidationOptions
  { failOnEpsilonReadsInput    :: Bool  -- hidden-input check
  , checkDeterminism           :: Bool  -- pure structural determinism check
  , checkReachability          :: Bool  -- structural dead-edge check
  , warnOpaqueGuards           :: Bool  -- advisory audit; default OFF
  , checkHeadRecoverability    :: Bool  -- head event recovers consumed fields
  , checkInversionAmbiguity    :: Bool  -- head wire constructor selects one edge
  , checkGuardImpliesInputRead :: Bool  -- input reads have a matching ctor guard
  , checkStateChangingEpsilon  :: Bool  -- output-free edges preserve durable state
  }
```

Construct custom settings by updating `defaultValidationOptions`, not by spelling a record literal. That keeps later checks enabled when the library grows.

```haskell
-- CORRECT: preserve every default and opt into the advisory audit.
auditOptions = defaultValidationOptions { warnOpaqueGuards = True }

-- WRONG: a handwritten record silently freezes today's option set.
-- frozenOptions = ValidationOptions { ... }
```

Never disable `checkStateChangingEpsilon` for a persisted transducer. An output-free edge that changes control state or registers leaves no event from which replay can reproduce that change.

## Repair Each Structured Warning

`TransducerValidationWarning` has eleven constructors in Keiki 0.4. The first seven participate in the configurable default contract, `OpaqueGuard` appears only when its audit is enabled, and the three projection warnings are unconditional integrity checks.

- `HiddenInput { tvwEdge, tvwInCtor, tvwMissingSlots, tvwDetail }` means an edge consumes command information that its output does not emit. Add the missing fields to the private event or stop reading them.
- `HeadUnrecoverable { tvwEdge, tvwInCtor, tvwTailOnlySlots, tvwDetail }` means a later event in a multi-event edge carries a consumed field that the first event lacks. Streaming replay inverts only the head event, so move every replay-critical field onto that event.
- `InversionAmbiguity { tvwSource, tvwEdgeA, tvwEdgeB, tvwWireCtor, tvwDetail }` means two outgoing edges share a head wire constructor. Give the edges distinct head events so an observed event selects one inverting edge.
- `UnguardedInputRead { tvwEdge, tvwInCtor, tvwDetail }` means an edge reads fields from an input constructor without first establishing the matching top-level constructor guard. Add the correct constructor guard so a different command cannot make evaluation throw.
- `StateChangingEpsilon { tvwEdge, tvwChangesVertex, tvwWritesRegisters, tvwDetail }` means an output-free edge changes durable state. Emit an event or make the edge inert.
- `NondeterministicPair { tvwSource, tvwEdgeA, tvwEdgeB, tvwInCtor, tvwDetail }` means two outgoing guards can hold for one command. Make them mutually exclusive; the runtime witness of this defect is `AmbiguousEdges`.
- `PossiblyDeadEdge { tvwEdge, tvwDetail }` means the source vertex is structurally unreachable or the guard is statically unsatisfiable. Remove the edge or repair its source and guard.
- `OpaqueGuard { tvwEdge, tvwDetail }` means the guard contains a `TApp` closure the symbolic analyses cannot inspect. Review and replace it with structural predicates, scalar facts, or an application-layer invariant.
- `ProjectionResultUnsupported { tvwEdge, tvwProjectionPath, tvwProjectionShape, tvwProjectionResultType, tvwDetail }` means a projected result lacks symbolic equality support. Expose a supported scalar or keep the predicate outside the transducer.
- `ProjectionOrderingUnsupported { tvwEdge, tvwProjectionPath, tvwProjectionShape, tvwProjectionResultType, tvwDetail }` means the projected field supports equality but not ordered comparison. Use equality, expose an orderable scalar, or move the ordering decision outward.
- `ProjectionOutsideGuard { tvwEdge, tvwProjectionPath, tvwProjectionShape, tvwProjectionLocation, tvwDetail }` means a projection appears in an update or output. Copy the whole owner or an ordinary scalar term there; projections are guard-only.

## Know What The Pure Determinism Pass Proves

The pure pass proves overlap within supported conjunction spines. It understands constructor consistency, exact integral intervals for integral variables, and concrete literal witnesses for other types. It deliberately stays silent on disjunction, negation, arithmetic, opaque terms, variable-versus-variable comparisons, and non-integral strict-bound density.

This direction has no false positives: every `NondeterministicPair` it reports is a real overlap. An empty result is not an exact proof for guards outside that fragment, so use the z3-backed checks when those constructs decide correctness.

## Audit Opaque Guards Explicitly

Turning on `warnOpaqueGuards` does not run an isolated check; it adds the advisory audit to the same default and unconditional checks. Filter for `OpaqueGuard` when you want only that inventory:

```haskell
opaqueGuards =
  [ warning
  | warning@OpaqueGuard{} <-
      validateTransducer
        defaultValidationOptions { warnOpaqueGuards = True }
        incidentTransducer
  ]
```

See [Collections and Opaque Guards](./collections-and-opaque-guards.md) for the sound alternatives to collection-content closures.

## Treat Field Projections As Structural, Not Opaque

A valid `TFieldProj` is visible to the symbolic translator, so the opt-in opaque audit does not flag it. An input-based projection still counts as an input read and requires the matching constructor guard. Keiki constrains projection variables from concrete owners when checking a supplied execution, but a satisfiable symbolic result is not proof that an arbitrary consumer-owned record can be reconstructed.

Generated Keiro witnesses add schema provenance and agreement tests; hand-written witnesses must be checked with `fieldWitnessAgrees`. See [Typed Field Projections](typed-field-projections.md).

## Escalate To The Solver For Exact Answers

The checks in `Keiki.Symbolic` ask z3 about the guards the pure fragment cannot settle:

```haskell
import Keiki.Symbolic
  ( checkDeadEdgesSym
  , checkTransitionDeterminismSym
  , satResultIsProvablyUnsat
  )

checkTransitionDeterminismSym incidentTransducer
checkDeadEdgesSym incidentTransducer
```

These pure-looking APIs require the `z3` executable on `PATH` and throw if it is unavailable. Keep them in a dedicated test group while retaining the fast umbrella in every test run.

Model numeric guards with the solver's representation in mind. Platform-sized `Int` is modeled as unbounded `Integer`; if a proof depends on overflow, use `Int32`, `Int64`, or a `Word*` type, whose fixed-width wraparound is modeled exactly. Solver uncertainty is conservative in 0.2: `Unknown`, `ProofError`, and every other non-definitive result do not prove disjointness or deadness. `satResultIsProvablyUnsat` returns `True` only for a definite unsatisfiable result.

## Why Keiro Makes This Mandatory

Keiro's `mkEventStream` runs the same umbrella at the durable stream boundary and returns `Left warnings` for any warning. It also force-enables head recoverability and state-changing-epsilon checks in custom option sets. A service that skips the CI assertion therefore discovers the same problem as a startup failure; validation warnings are deployment blockers, not advice.

Use this test shape for every service:

```haskell
describe "Keiki well-formedness" do
  it "incident aggregate validates clean" do
    validateTransducer defaultValidationOptions incidentTransducer
      `shouldBe` []

  it "escalation orchestrator validates clean" do
    validateTransducer defaultValidationOptions escalationTransducer
      `shouldBe` []

  it "incident aggregate has no opaque guards" do
    opaqueGuards `shouldBe` []
```

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) explains the authoring rules these checks enforce.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) shows the runtime failure surface the replay-safety checks prevent.
- [Diagnosing Rejected Commands](./diagnosing-rejected-commands.md) covers the forward-execution counterpart to build-time determinism.
- [Collections and Opaque Guards](./collections-and-opaque-guards.md) explains how to eliminate or audit opaque predicates.
- [Typed Field Projections](./typed-field-projections.md) defines the guard-only projection boundary and witness laws.
