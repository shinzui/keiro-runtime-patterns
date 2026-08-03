---
type: Guide
title: "Build-Time Validation of Keiki Transducers"
description: "Asserting transducers and typed field projections are well-formed in CI with validateTransducer"
timestamp: 2026-08-02T19:56:33-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-build-time-validation
tags: [keiki, build-time-validation]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-28T19:53:40-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; verified exported symbols, signatures, version claims, and links.
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

`TransducerValidationWarning` has eleven constructors through Keiki 0.8. The first seven participate in the configurable default contract, `OpaqueGuard` appears only when its audit is enabled, and the three projection warnings are unconditional integrity checks.

- `HiddenInput { tvwEdge, tvwInCtor, tvwMissingSlots, tvwDetail }` means an edge consumes command information that its output does not emit. Add the missing fields to the private event or stop reading them.
- `HeadUnrecoverable { tvwEdge, tvwInCtor, tvwTailOnlySlots, tvwDetail }` means a later event in a multi-event edge carries a consumed field that the first event lacks. Streaming replay inverts only the head event, so move every replay-critical field onto that event.
- `InversionAmbiguity { tvwSource, tvwEdgeA, tvwEdgeB, tvwWireCtor, tvwDetail }` means two outgoing edges share a head wire constructor. Give the edges distinct head events so an observed event selects one inverting edge.
- `UnguardedInputRead { tvwEdge, tvwInCtor, tvwDetail }` means an edge reads fields from an input constructor without first establishing the matching top-level constructor guard. Add the correct constructor guard so a different command cannot make evaluation throw.
- `StateChangingEpsilon { tvwEdge, tvwChangesVertex, tvwWritesRegisters, tvwDetail }` means an output-free edge changes durable state. Emit an event or make the edge inert.
- `NondeterministicPair { tvwSource, tvwEdgeA, tvwEdgeB, tvwInCtor, tvwDetail }` means two outgoing guards can hold for one command. Make them mutually exclusive; the runtime witness of this defect is `AmbiguousEdges`.
- `PossiblyDeadEdge { tvwEdge, tvwDetail }` means the source vertex is structurally unreachable or the guard is statically unsatisfiable. Remove the edge or repair its source and guard.
- `OpaqueGuard { tvwEdge, tvwDetail }` means the guard contains a term the symbolic translator must make opaque: a `TApp1`/`TApp2` closure, or a `TArith` whose carrier is outside the symbolic numeric registry. Review and replace it with structural predicates, a registered numeric carrier, scalar facts, or an application-layer invariant. Do not assert on the detail string; it names no specific constructor.
- `ProjectionResultUnsupported { tvwEdge, tvwProjectionPath, tvwProjectionShape, tvwProjectionResultType, tvwDetail }` means a projected result lacks symbolic equality support. Expose a supported scalar or keep the predicate outside the transducer.
- `ProjectionOrderingUnsupported { tvwEdge, tvwProjectionPath, tvwProjectionShape, tvwProjectionResultType, tvwDetail }` means the projected field supports equality but not ordered comparison. Use equality, expose an orderable scalar, or move the ordering decision outward.
- `ProjectionOutsideGuard { tvwEdge, tvwProjectionPath, tvwProjectionShape, tvwProjectionLocation, tvwDetail }` means a projection appears in an update or output. Copy the whole owner or an ordinary scalar term there; projections are guard-only.

## Know What The Pure Determinism Pass Proves

The pure pass proves overlap within supported conjunction spines. It understands constructor consistency, exact integral intervals for integral variables, and concrete literal witnesses for other types. `Natural` carries the exact interval `[0, ∞)`, so the pass can produce interior witnesses for it rather than only literal ones. It deliberately stays silent on disjunction, negation, arithmetic, opaque terms, variable-versus-variable comparisons, and non-integral strict-bound density.

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

A valid `TFieldProj` is visible to the symbolic translator, so the opt-in opaque audit does not flag it. An input-based projection still counts as an input read and requires the matching constructor guard. Visible is not the same as exact, though: a plain one-way `fieldWitness` yields `UnconstrainedProjection` and downgrades the whole predicate's translation strength, because a satisfiable symbolic result is no proof that an arbitrary consumer-owned record can be reconstructed.

Generated Keiro witnesses add schema provenance and agreement tests; hand-written witnesses must be checked with `fieldWitnessAgrees`. See [Typed Field Projections](typed-field-projections.md) for the boundary and [Exact Projection Domains](exact-projection-domains.md) for the declaration that restores proof strength.

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

Model numeric guards with the solver's representation in mind. Platform-sized `Int` is modeled as unbounded `Integer`; if a proof depends on overflow, use `Int32`, `Int64`, or a `Word*` type, whose fixed-width wraparound is modeled exactly. `Natural` is modeled as an unbounded integer constrained non-negative at every allocation, and its subtraction is total monus in both evaluators; see [Keiki Transducer Best Practices](./transducer-best-practices.md). Solver uncertainty is conservative: `Unknown`, `ProofError`, and every other non-definitive result do not prove disjointness or deadness. `satResultIsProvablyUnsat` returns `True` only for a definite unsatisfiable result.

## Never Read A Verification Result As A Bare Boolean

When a test asks the solver about one predicate directly, use `verifyPredicate` rather than reducing a `SatResult` to `Bool` yourself:

```haskell
import Keiki.Symbolic (PredicateVerification (..), predicateTranslationExact, verifyPredicate)

-- CORRECT: an inexact translation and an indefinite solver answer stay distinguishable.
verifyPredicate reservationGuard >>= \case
  VerifiedUnsatisfiable      -> pure ()          -- proved: the guard cannot hold
  VerifiedSatisfiable        -> pure ()          -- proved: a witness exists
  UnverifiedOpaque           -> failWith "guard is not exactly translatable"
  UnverifiedSolverUnknown m  -> failWith m       -- Unknown, DeltaSat, SatExtField
  UnverifiedSolverFailure m  -> failWith m       -- ProofError, contract violation
```

Since Keiki 0.7 `verifyPredicate` is a compatibility projection of `verifyPredicateDetailed`: it always runs the solver, and it reports `Verified*` only when the translation was exact for the whole predicate. A conservative translation collapses to `UnverifiedOpaque` whether the solver answered SAT or UNSAT. Only definite UNSAT under an exact translation counts as a proof; `symIsBot`, the determinism check, and the dead-edge check share the same failure-aware kernel.

Only the two `Verified*` constructors are evidence. Treat the three `Unverified*` constructors as an unproven model, never as a pass. Use `predicateTranslationExact` alone when a test asserts that a guard stays exactly translatable without paying for a solver run — it is stricter than `translatePred` accepting the predicate, because that translation substitutes fresh variables for unsupported pieces on purpose.

## Explain An Inexact Translation Before Rewriting The Guard

`predicateTranslationReport` returns the `TranslationStrength` — `ExactTranslation`, or `ConservativeOverApproximation` with a non-empty ordered list of `TranslationIssue` values naming exactly what was lost:

- `OpaqueApplication` — a `TApp1`/`TApp2` closure.
- `UnsupportedEquality` / `UnsupportedOrdering` / `UnsupportedArithmetic` — a carrier outside the corresponding symbolic registry.
- `UnconstrainedProjection` — a field projection read through a plain one-way `fieldWitness`. This is the common cause; see [exact projection domains](exact-projection-domains.md).
- `UnsupportedProjectionDomain` — a declared exact domain the backend cannot constrain.
- `ProjectionUsedOutsideEquality` — a projected value compared by something other than equality.
- `ConflictingProjectionViews` — one owner read through disagreeing tags.
- `DirectAndProjectedOwnerRead` — one owner read both whole and through a projection.
- `UnguardedProjectionInputRead` — an input projection without its matching constructor guard.

Fix the named issue rather than weakening the assertion. Do not pattern-match on rendered detail strings.

## Read The Detailed Verification Result When Exactness Matters

`verifyPredicateDetailed` returns `PredicateVerificationDetail`, which carries the `TranslationStrength` alongside the solver status and, for a satisfiable exact result, checked path-local `ProjectionModel` values recovered with `projectionModelKeyAs` and `projectionModelOwnerAs`. Its fifth constructor, `PredicateProjectionContractViolation`, has no compatibility equivalent worth acting on: it means a declared projection inverse rejected a key the solver admitted, which is a declaration defect. `checkTransitionDeterminismSymDetailed` and `checkDeadEdgesSymDetailed` expose the same evidence for the two edge analyses.

Projection models are path-local key/owner pairs, not complete register or input witnesses. Use them to explain a counterexample, never as a replacement for `symSatExt`.

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
