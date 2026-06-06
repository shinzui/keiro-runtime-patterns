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

## Add Replay-Safety Tests For Every Transducer

Every service test suite should assert that each aggregate has no hidden replay
inputs.

```haskell
import Keiki.Core (checkHiddenInputs)

testKeikiReplaySafety :: IO ()
testKeikiReplaySafety = do
  assertEqual "incident transducer has no hidden replay inputs" [] (checkHiddenInputs incidentTransducer)
  assertEqual "reservation transducer has no hidden replay inputs" [] (checkHiddenInputs reservationTransducer)
```

If this assertion fails, inspect the named edge. Usually the fix is to add the
missing command field to the emitted private event, or to remove the hidden command
field read from the guard/update.

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

If the service prelude re-exports lens operators, `(.>)` may conflict. Hide the lens
operator in the affected aggregate module:

```haskell
import MyService.Prelude hiding (Index, (.>))
```

Then import Keiki's operator from `Keiki.Core`.

## Use `derive*All` When Helper Names Match Constructors

Use the all-derived Template Haskell helpers whenever the generated helper suffix
should equal the constructor name.

Preferred:

```haskell
$(deriveAggregateCtorsAll ''CapacityCommand ''CapacityRegs)
$(deriveWireCtorsAll ''CapacityEvent)
```

Avoid spelling out identity mappings:

```haskell
$(deriveAggregateCtors ''CapacityCommand ''CapacityRegs
  [ ("ReportCapacity", "ReportCapacity")
  , ("ReserveIcuBed", "ReserveIcuBed")
  ])
```

Keep the explicit `deriveAggregateCtors` or `deriveWireCtors` form only when at least
one helper name intentionally differs from the constructor name, for example:

```haskell
$(deriveAggregateCtors ''IncidentCommand ''IncidentRegs
  [ ("DeclareIncident", "Declare")
  , ("AssignCommander", "AssignCommander")
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

Until Keiki has structural collection operations, commands sometimes carry a full
updated list, such as `activeResourceIds` or `pendingReservationIds`. This is
acceptable, but it means the aggregate is trusting the caller to compute the new list
correctly.

When using this pattern:

- The command processor or router must compute the collection deterministically.
- The emitted private event must carry the full collection if replay needs it.
- Tests should cover duplicate, remove, and idempotent retry behavior outside Keiki.

Prefer future Keiki collection operators if available, such as `member`, `notMember`,
`insert`, or `remove`, so the aggregate owns the invariant.

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
- Add the process-manager transducer to the same `checkHiddenInputs` replay-safety
  test as aggregate transducers.
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
- Use `step` in the pure command runner.
- Use readable Keiki predicate and arithmetic operators.
- Ensure emitted private events carry every command field read by guards or updates.
- Add a `checkHiddenInputs transducer == []` test.
- Add command tests for rejected guards and accepted transitions.
- Add replay tests for any edge that reads command fields in guards.
- Generate or review the Mermaid diagram for the aggregate.
- If the transducer backs a process manager, test timer-fired and already-settled
  paths as well.
