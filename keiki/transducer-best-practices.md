# Keiki Transducer Best Practices

Use this guide when building Keiki-backed transducers for Keiro runtime projects:
aggregates, process-manager state streams, and other durable state machines. It
captures the practices that prevent hydration/replay failures and keeps modules close
to the current Keiki DSL.

## Use Keiki For Durable State Machines

Keiki is for pure durable transducers: command guards, typed register updates, event
emission, replay, and diagram generation. In a Keiro service, that includes ordinary
aggregates and process-manager state streams such as escalation or surge tracking. Do
not use Keiki as a generic JSON validation layer or as a replacement for service
integration contracts.

Decode and validate external messages at the service boundary. Convert accepted
messages into service-owned commands or process-manager inputs, then let the Keiki
transducer decide whether those commands are valid in the current durable state.

## Author With The Builder DSL

Prefer `Keiki.Builder` over hand-written `Edge` values.

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

## Add Build-Time Validation Tests For Every Transducer

Every service test suite should assert that each aggregate is well-formed. Prefer the
umbrella check `validateTransducer`, which in one call covers hidden replay inputs,
nondeterministic (overlapping) guards, and unreachable/dead edges — and is pure (no z3):

```haskell
import Keiki.Core (validateTransducer, defaultValidationOptions)

testKeikiValidation :: IO ()
testKeikiValidation = do
  assertEqual "incident transducer is well-formed" [] (validateTransducer defaultValidationOptions incidentTransducer)
  assertEqual "reservation transducer is well-formed" [] (validateTransducer defaultValidationOptions reservationTransducer)
```

Each entry in the result is a structured `TransducerValidationWarning s` you can
pattern-match on — `HiddenInput`, `NondeterministicPair`, or `PossiblyDeadEdge` — each
naming the offending edge by its typed `EdgeRef`. If the assertion fails, inspect the
named edge: a `HiddenInput` usually means a guard/update reads a command field the emitted
private event does not carry (add the field, per the rule above); a `NondeterministicPair`
means two outgoing guards overlap (tighten one); a `PossiblyDeadEdge` means a vertex is
unreachable or a guard is statically unsatisfiable.

`checkHiddenInputs t` alone is still available if you want only the hidden-input slice, but
`validateTransducer` is the recommended single assertion. For the exact, solver-backed
determinism and dead-edge answers (which prove overlaps the pure path cannot), call
`Keiki.Symbolic.checkTransitionDeterminismSym` / `checkDeadEdgesSym`. See
[build-time-validation.md](./build-time-validation.md) for the full menu, including the
opt-in opaque-guard audit.

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

## Process-Manager State Streams

Keiro process managers can use Keiki for their own durable state stream, separate from
the target aggregate stream. This is the right pattern when the process needs to
remember acknowledgements, scheduled timers, escalation levels, follow-up state, or
other cross-event progress.

Use this shape:

```haskell
type EscalationEventStream =
  EventStream
    (HsPred EscalationRegs EscalationCommand)
    EscalationRegs
    EscalationState
    EscalationCommand
    EscalationEvent

incidentEscalationProcessManager =
  ProcessManager
    { eventStream = escalationEventStream
    , targetEventStream = incidentEventStream
    , handle = \input -> ProcessManagerAction { command, commands, timers }
    }
```

Best practices:

- Model the process manager's durable state as a normal Keiki transducer.
- Keep process-manager commands and events private to the service.
- Keep the target aggregate command separate from the process-manager command.
- Emit all timer IDs, correlation IDs, and command fields needed to replay the
  process-manager state stream.
- Add the process-manager transducer to the same `validateTransducer defaultValidationOptions`
  and opaque-guard audit tests as aggregate transducers.
- Make timer-fired commands idempotent: if the process has already settled, command
  rejection should be acceptable to the timer worker.

Do not store process-manager progress only in timers or read models. Timers are wakeup
mechanisms, and read models are projections; the Keiki process-manager stream is the
durable source of truth for the process state.

## Minimum Checklist For A New Keiki Transducer

- Define a small typed register file.
- Seed every register with a deliberate initial value.
- Define command payloads and private event payloads separately.
- Use `deriveAggregateCtorsAll` and `deriveWireCtorsAll` unless helper names need
  custom suffixes.
- Author edges with `Keiki.Builder`.
- Use `step` in the pure command runner; use `stepEither` where you need the rejection reason.
- Use readable Keiki predicate and arithmetic operators (and the `B.requireGt`-style verbs
  to dodge any lens operator clash).
- Ensure emitted private events carry every command field read by guards or updates.
- Add a `validateTransducer defaultValidationOptions transducer == []` test (covers hidden
  inputs, determinism, and dead edges in one assertion).
- If the aggregate guards on collection contents through a `TApp`, run the
  `warnOpaqueGuards = True` audit and confirm you understand each `OpaqueGuard`.
- Add command tests for rejected guards and accepted transitions.
- Add replay tests for any edge that reads command fields in guards.
- Generate or review the Mermaid diagram for the aggregate.
- If the transducer backs a process manager, test timer-fired and already-settled
  paths as well.
