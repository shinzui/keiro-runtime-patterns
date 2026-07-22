# Keiki Transducer Best Practices

**Author replay-safe transducers whose private events make every durable decision reproducible.**

Use this guide when building Keiki-backed transducers for Keiro runtime projects:
aggregates, orchestrator transducers, and other durable state machines. It
captures the practices that prevent hydration/replay failures and keeps modules close
to the current Keiki DSL.

## Use Keiki For Durable State Machines

Keiki is for pure durable transducers: command guards, typed register updates, event
emission, replay, and diagram generation. In a Keiro service, that includes ordinary
aggregates and orchestrators such as escalation or surge tracking. Do
not use Keiki as a generic JSON validation layer or as a replacement for service
integration contracts.

Decode and validate external messages at the service boundary. Convert accepted
messages into service-owned commands or process-manager inputs, then let the Keiki
transducer decide whether those commands are valid in the current durable state.

## Author With The Builder DSL

Prefer `Keiki.Builder` over hand-written `Edge` values.

Builder modules need the two syntax extensions, a qualified builder import, and an
unqualified assignment operator. The unqualified import is load-bearing for field-keyed
assignment inside `B.do` blocks:

```haskell
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE QualifiedDo #-}

import qualified Keiki.Builder as B
import Keiki.Builder ((.=))
```

Use this shape:

```haskell
aggregateTransducer =
  B.buildTransducer InitialVertex initialRegs isTerminal do
    B.from InitialVertex do
      B.onCmd inCtorSomeCommand $ \d -> B.do
        B.requireGuard (d.count .>= lit 0)
        B.slot @"aggregateId" =: d.aggregateId
        B.emit wireSomeEvent SomeEventTermFields
          { aggregateId = d.aggregateId
          , commandId = d.commandId
          , count = d.count
          }
        B.goto NextVertex
```

Use direct AST construction only when the builder cannot express the edge shape.
If a transducer needs many direct AST edges, treat that as a design review signal.

Every `onCmd` and `onEpsilon` body must declare output intent before `goto`. Use `emit` or
`emitWith` for persisted output, and call `noEmit` when the edge is deliberately silent.
Reaching `goto` without any of those calls is an eager construction error in 0.2:

```haskell
-- WRONG: rejected at construction because output intent is missing.
B.onCmd inCtorAcknowledge $ \d -> B.do
  B.requireEq (B.reg @"settled") (lit False)
  B.goto Acknowledged

-- CORRECT: this edge is deliberately silent.
B.onCmd inCtorAcknowledge $ \d -> B.do
  B.requireEq (B.reg @"settled") (lit False)
  B.noEmit
  B.goto Acknowledged
```

`buildTransducer` preserves the convenient value-returning API and throws a rendered builder
error for malformed edges. Prefer `buildTransducerEither` in tests, CLIs, and other callers
that must handle construction failures as values; it returns all located `BuilderError`
values, which `renderBuilderErrors` formats in declaration order. Both builders now require
`DistinctNames (Names rs)` so duplicate register-slot names fail at compile time and `Eq v`
for vertex grouping; the old `Bounded v` and `Enum v` constraints are gone.

## Prefer `step` Over `delta` Plus `omega`

Do not run command wrappers by calling `delta` and then `omega` manually. Use
`step`, which is Keiki's high-level pure entry point for one command.

Preferred:

```haskell
runSomeCommand vertex regs command = do
  (nextVertex, nextRegs, events) <- step someTransducer (vertex, regs) command
  pure (events, nextVertex, nextRegs)
```

Avoid:

```haskell
runSomeCommand vertex regs command = do
  (nextVertex, nextRegs) <- delta someTransducer vertex regs command
  let events = omega someTransducer vertex regs command
  pure (events, nextVertex, nextRegs)
```

The manual form repeats matching work and hides the fact that `step` is the intended
aggregate execution API.

When `step` returns `Nothing` and you need to know *why* a command was rejected — no
outgoing edges, no matching guard, or two guards matched (ambiguity) — use `stepEither`,
which returns `Either (StepFailure s) (s, RegFile rs, [co])` with the exact reason on the
`Left` and the identical success triple on the `Right`. See
[diagnosing-rejected-commands.md](./diagnosing-rejected-commands.md). Prefer `stepEither`
in command processors that surface rejection reasons to callers or logs; keep `step` where
a bare accept/reject is enough.

## Emit Every Command Field Needed For Replay

This is the most important rule.

Keiki replay reconstructs the input command from emitted events. If a guard or update
reads a command field, the event output for that edge must carry enough information
for Keiki to reconstruct that field.

Bad pattern:

```haskell
B.onCmd inCtorRequestTransferReservation $ \d -> B.do
  B.requireGuard (d.divertStatus ./= lit TotalDivert .|| d.lifeCriticalOverride .== lit True)
  B.slot @"reservationId" =: d.reservationId
  B.emit wireTransferReservationCreated TransferReservationCreatedTermFields
    { reservationId = d.reservationId
    , hospitalId = d.hospitalId
    }
```

This edge reads `divertStatus` and `lifeCriticalOverride`, but the event does not
emit them. Later hydration can fail because Keiki cannot recover the original command
that satisfied the guard.

Good pattern:

```haskell
B.onCmd inCtorRequestTransferReservation $ \d -> B.do
  B.requireGuard (d.divertStatus ./= lit TotalDivert .|| d.lifeCriticalOverride .== lit True)
  B.slot @"reservationId" =: d.reservationId
  B.emit wireTransferReservationCreated TransferReservationCreatedTermFields
    { reservationId = d.reservationId
    , hospitalId = d.hospitalId
    , divertStatus = d.divertStatus
    , lifeCriticalOverride = d.lifeCriticalOverride
    }
```

The private event does not need to match the public integration message. Keep public
contracts bounded-context safe, but make private aggregate events replay-invertible.

For a multi-event edge, the first emitted event must carry every command field the edge
consumes. Streaming replay chooses and inverts an edge from that head event alone; tail events
are only equality-checked against the remaining expected queue. Tail-only coverage produces
`HeadUnrecoverable`. See [Structured Replay and Hydration](./structured-replay-and-hydration.md)
for `reconstituteEither`, `replayEvents`, and the structured failure surface.

## Add Build-Time Validation Tests For Every Transducer

Every service test suite should assert that each aggregate is well-formed. Prefer the
umbrella check `validateTransducer`, which runs seven default-on checks and is pure (no z3):

```haskell
import Keiki.Core (validateTransducer, defaultValidationOptions)

testKeikiValidation :: IO ()
testKeikiValidation = do
  assertEqual "incident transducer is well-formed" [] (validateTransducer defaultValidationOptions incidentTransducer)
  assertEqual "reservation transducer is well-formed" [] (validateTransducer defaultValidationOptions reservationTransducer)
```

Each entry in the result is a structured `TransducerValidationWarning s` you can
pattern-match on. The eight constructors are `HiddenInput`, `HeadUnrecoverable`,
`InversionAmbiguity`, `UnguardedInputRead`, `StateChangingEpsilon`, `NondeterministicPair`,
`PossiblyDeadEdge`, and the opt-in `OpaqueGuard`; each names the offending edge or edge pair.
Fix the model rather than suppressing a warning.

Keiro's `mkEventStream` runs this same umbrella at service startup and returns `Left warnings`
for any finding. It force-enables the head-recoverability and state-changing-epsilon checks at
the durable boundary, so a warning here is a deployment blocker rather than advice.

`checkHiddenInputs t` alone is still available if you want only the hidden-input slice, but
`validateTransducer` is the recommended single assertion. For the exact, solver-backed
determinism and dead-edge answers (which prove overlaps the pure path cannot), call
`Keiki.Symbolic.checkTransitionDeterminismSym` / `checkDeadEdgesSym`. See
[build-time-validation.md](./build-time-validation.md) for all warning-specific fixes, the
opt-in opaque-guard audit, and the solver escalation path.

## Prefer Readable Predicate Operators

Prefer Keiki's structural predicate operators when they improve readability:

```haskell
B.requireGuard (B.reg @"closed" .== lit False)
B.requireGuard (d.availableIcuBeds .>= lit 0)
B.requireGuard (B.reg @"availableIcuBeds" .> lit 0)
B.requireGuard (d.availableUnits .< d.thresholdUnits)
B.requireGuard (d.divertStatus ./= lit TotalDivert .|| d.lifeCriticalOverride .== lit True)
```

Use arithmetic term operators for register updates:

```haskell
B.slot @"availableIcuBeds" =: (B.reg @"availableIcuBeds" .- lit 1)
B.slot @"reservedIcuBeds" =: (B.reg @"reservedIcuBeds" .+ lit 1)
```

If the service prelude re-exports `lens`/`generic-lens`, the bare `(.>)` conflicts (in
`lens` it is optic composition; in Keiki it is greater-than). There are three fixes — pick
per module:

```haskell
-- A. hide and re-import (fine for a handful of operators)
import MyService.Prelude hiding (Index, (.>))
import Keiki.Core (lit, (.>), (.>=), (.+), (.-))

-- B. qualified Keiki.Operators (no hiding list to maintain)
import qualified Keiki.Operators as K
-- ... then write `B.reg @"x" K..> lit 0`

-- C. inside a builder block, use the clash-free guard verbs (no operator at all)
B.requireGt (B.reg @"availableIcuBeds") (lit 0)
B.requireGe d.availableUnits           (lit 1)
```

Prefer **C** (`B.requireGt`/`requireGe`/`requireLt`/`requireLe`/`requireEq`) when authoring
a guard inside a `B.do` block — it never clashes and needs no import gymnastics. Reach for
A or B only when building a compound `HsPred` value outside a builder. See
[operator-conflicts.md](./operator-conflicts.md).

## Use `derive*All` Or `derive*With` Instead Of Manual Enumeration

Use the all-derived Template Haskell helpers whenever the generated helper suffix
should equal the constructor name.

Preferred:

```haskell
$(deriveAggregateCtorsAll ''CapacityCommand ''CapacityRegs)
$(deriveWireCtorsAll ''CapacityEvent)
```

When only a few helper suffixes differ, prefer the `With` variants and override just
those constructors:

```haskell
$(deriveAggregateCtorsWith ''IncidentCommand ''IncidentRegs
    defaultDeriveCtorOptions
      { suffixOverrides = Map.fromList [("DeclareIncident", "Declare")]
      }
  )
```

Use the same pattern with `deriveWireCtorsWith` and `defaultDeriveWireOptions` when an
event helper suffix differs from its constructor. Keep explicit `deriveAggregateCtors`
or `deriveWireCtors` enumeration only as a legacy fallback for older Keiki versions.

Avoid spelling out identity mappings:

```haskell
$(deriveAggregateCtors ''CapacityCommand ''CapacityRegs
  [ ("ReportCapacity", "ReportCapacity")
  , ("ReserveIcuBed", "ReserveIcuBed")
  ])
```

## Keep Register Types Small And Explicit

Registers should hold durable aggregate state needed for later decisions. Avoid using
registers as unstructured caches of entire external messages.

Good register slots:

- Aggregate identity.
- Current lifecycle state flags.
- Counters and totals used by guards.
- IDs of pending local work.
- Private state needed to produce future events.

Poor register slots:

- Raw external JSON payloads.
- Public integration envelopes.
- Values that are only needed by a read model.
- Large collections that the aggregate cannot update safely.

## Be Careful With Whole-Collection Command Fields

Keiki has **no** structural collection operations, and as of the 2026-06 design review
they are **deferred** (a prototype was built and ratified NO-GO; see
[collections-and-opaque-guards.md](./collections-and-opaque-guards.md)). Keiki's own
modeling guide gives the rule: project collection facts into scalar tallies for guards,
and promote elements with identity and lifecycle into their own aggregates or coordinated
streams.

Sometimes a command still carries a full updated list, such as `activeResourceIds` or
`pendingReservationIds`, and the aggregate stores it wholesale with `=:`. This is acceptable
for read-model-style summaries — and, importantly, it is **fully replay-safe and verified**:
a whole list arriving on the command
(`B.slot @"items" =: d.items`) is a *structural* input read, so `solveOutput` inverts it
and `validateTransducer` sees the whole list on the wire. It just means the aggregate
trusts the caller to have computed the list correctly.

When using this pattern:

- The command processor or router must compute the collection deterministically.
- The emitted private event must carry the full collection if replay needs it.
- Keep append/remove/membership invariants in the application layer (against the read
  model) and test duplicate/remove/idempotent-retry behavior there.
- Your only *in-aggregate* collection guard should stay structural — e.g.
  `B.reg @"items" .== lit []` (emptiness). That is verifiable today.

The thing to avoid is an **opaque collection guard**: lifting `Map.member`/`all`/`null`/
`elem` through a `TApp` closure to branch on collection *contents*. It compiles and
evaluates, but Keiki's symbolic checker cannot see through it and silently under-verifies
the edge — a green build that did not check what you think it did. To catch these, run the
opt-in audit:

```haskell
validateTransducer defaultValidationOptions { warnOpaqueGuards = True } myTransducer
-- ⇒ [ OpaqueGuard { tvwEdge = EdgeRef { ... } }, ... ]   -- guards the solver couldn't see
```

If you genuinely need a per-element collection invariant *inside* the aggregate, the sound
option today is to split the lifecycle-bearing sub-entity into its own scalar aggregate
(the sub-entity-as-aggregate pattern), which gets full Keiki guarantees per sub-aggregate.
First-class collection registers (`UInsert`/`PMember`/`TLookupField`) may be revived if a
real keyed-collection consumer appears. See
[collections-and-opaque-guards.md](./collections-and-opaque-guards.md).

## Keep Private Events Replay-Oriented

Private aggregate events and public integration messages serve different purposes.

Private Keiki events should be shaped for:

- Rehydrating the aggregate exactly.
- Reconstructing commands for replay.
- Carrying all fields needed by guards and updates.
- Feeding local read models.

Public integration messages should be shaped for:

- Bounded-context contracts.
- Cross-service compatibility.
- Stable schema evolution.
- Avoiding private aggregate leakage.

Do not remove a private event field only because the public contract does not need it.
That can break Keiki replay.

## Prefer Service-Owned Accessors For Register Reads

Use typed register accessors at module boundaries:

```haskell
reservationState :: RegFile ReservationRegs -> ReservationVertex
reservationState regs = regs ! (#reservationState :: Index ReservationRegs ReservationVertex)
```

This keeps test and read-model code from depending on register ordering or internal
slot machinery.

## Use Diagrams As A Regression Tool

If the service exposes Keiki diagram generation, keep it wired to the actual
transducers. Regenerate diagrams after meaningful aggregate changes and review:

- Unexpected missing transitions.
- Unexpected terminal states.
- Edges with surprising source or target vertices.
- Multi-event command edges.

Diagrams do not replace tests, but they catch modeling mistakes quickly.

## Orchestrators Are Transducers Too

Keiki has no separate process-manager, saga, policy, or reactor abstraction. An orchestrator
is itself a transducer: an aggregate maps commands to events, while an orchestrator maps
events to commands. Author it with the same builder, validate it with the same
`validateTransducer`, and wire it with `compose`, `composeChecked`, `alternative`, or the
limited `feedback1` combinator from `Keiki.Composition`. See
[Checked Composition](./checked-composition.md) before choosing a composition boundary.

The hosted, durable `ProcessManager` record belongs to keiro's `Keiro.ProcessManager`. It
adds correlation keys, a saga event stream, target dispatch, atomic actions, and durable
timers around a keiki transducer. The complete hosted pattern will be documented by
[EP-5](../docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md).

## Minimum Checklist For A New Keiki Transducer

- Define a small typed register file.
- Seed every register with a deliberate initial value.
- Define command payloads and private event payloads separately.
- Use `deriveAggregateCtorsAll` and `deriveWireCtorsAll` unless helper names need
  custom suffixes.
- Author edges with `Keiki.Builder`.
- Declare output intent on every edge with `emit`, `emitWith`, or `noEmit`.
- Use `step` in the pure command runner; use `stepEither` where you need the rejection reason.
- Use readable Keiki predicate and arithmetic operators (and the `B.requireGt`-style verbs
  to dodge any lens operator clash).
- Ensure emitted private events carry every command field read by guards or updates.
- Add a `validateTransducer defaultValidationOptions transducer == []` test covering all seven
  default-on checks.
- If the aggregate guards on collection contents through a `TApp`, run the
  `warnOpaqueGuards = True` audit and confirm you understand each `OpaqueGuard`.
- Add command tests for rejected guards and accepted transitions.
- Add a replay round-trip test with `replayEvents` or `reconstituteEither` for any edge that
  reads command fields in guards.
- Generate or review the Mermaid diagram for the aggregate.
- If the transducer backs a keiro process manager's saga stream, test timer-fired and
  already-settled paths as well.

## Related Patterns

- [Build-Time Validation](./build-time-validation.md) is the complete warning and solver guide.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) turns replay failures into actionable diagnostics.
- [Checked Composition](./checked-composition.md) defines safe aggregate and orchestrator boundaries.
- [Event Schema Evolution](./event-schema-evolution.md) keeps persisted private-event JSON compatible.
- [Diagnosing Rejected Commands](./diagnosing-rejected-commands.md) explains forward command failures.
- [Collections and Opaque Guards](./collections-and-opaque-guards.md) keeps collection invariants verifiable.
- [Keiki Diagram Documentation](./diagram-docs.md) derives visual regression evidence from executable machines.
