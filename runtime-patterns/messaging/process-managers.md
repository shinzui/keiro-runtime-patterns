---
type: Standard
title: "Process Managers And Durable Timers"
description: "The process manager standard: saga streams, deterministic ids, worker policies, durable timers, and the orchestration decision ladder"
timestamp: 2026-07-22T11:19:01-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-process-managers
tags: [messaging, process-managers]
status: current
---

# Process Managers And Durable Timers

**Use an event-sourced saga for stateful orchestration, deterministic dispatch for crash recovery, and durable timers for deadlines.**

Use this standard when one service coordinates several events or aggregates over time. It defines the released Keiro 0.3 process-manager boundary, its Shibuya worker policy, and the decision ladder between a small reactor, a full process manager, and a durable workflow.

## The Rule

Choose a `ProcessManager` when a reaction needs durable per-correlation state, a deadline, or deterministic command dispatch. Keep its reaction pure, make every emitted identity stable under redelivery, and design correlated inputs from different streams to arrive in either order.

## Anatomy Of A Manager

The released definition wires the manager's own event stream to one target event-stream type:

```haskell
data ProcessManager input phi rs s ci co targetPhi targetRs targetState targetCi targetCo =
  ProcessManager
    { name :: Text
    , correlate :: input -> Text
    , eventStream :: ValidatedEventStream phi rs s ci co
    , streamFor :: Text -> Stream (EventStream phi rs s ci co)
    , targetEventStream :: ValidatedEventStream targetPhi targetRs targetState targetCi targetCo
    , targetProjections :: Stream targetCi -> [InlineProjection targetCo]
    , handle :: input -> ProcessManagerAction ci targetCi
    }
```

`name` is a stable identity used in deterministic write ids. `correlate` maps an input to the manager instance that owns it. `eventStream` and `streamFor` define the manager's own durable saga state. `targetEventStream` and `targetProjections` describe the aggregate commands it can dispatch. `handle` is the pure reaction.

The manager's state is an event stream, not a mutable saga row. Use stream names shaped `pm:<manager-name>-<correlation-id>` so every instance of one manager belongs to category `pm:<manager-name>`, and give each manager type its own category subscription. Prefer that category over an all-streams subscription.

The reaction value is deliberately small:

```haskell
data ProcessManagerAction ci targetCi = ProcessManagerAction
  { command :: ci
  , commands :: [PMCommand targetCi]
  , timers :: [TimerRequest]
  }

data PMCommand targetCi = PMCommand
  { target :: Stream targetCi
  , command :: targetCi
  }
```

For the same input, `handle` must return the same manager command, target-command order, and timer identities. Do not read a clock, database, random generator, or network inside it. Put source timestamps and required context into the input before calling the manager.

## Know The Transaction Boundary

The manager reaction is crash-safe, but it is not one transaction spanning every target aggregate.

When the manager command appends an event, that append and its `scheduleTimerTx` calls commit in one transaction. A no-op manager command has no append callback, so a timer-only reaction schedules its timers in a separate transaction. After manager state is settled, each target command and its inline projections commit in their own transaction.

This smaller boundary is intentional. A crash can leave manager history committed while some target commands are missing. Replaying the source event runs the target-dispatch loop again; stable event ids collapse already completed work and fill only the missing writes. A rejected target can also leave this history split, so a service using `RejectedDeadLetter` needs an operator loop that reconciles the durable dispatch dead letter with domain-specific saga history.

Keep each transaction short. Target inline projections and timer scheduling must do only the SQL needed for the invariant they protect; Kiroku's appending transaction holds the global `$all` row lock until commit.

## Make Replay Idempotent

Keiro derives the manager-state event id and every target-command event id with `deterministicCommandId`, a UUIDv5 over manager name, correlation id, source event id, and emit index. Index `-1` is the manager-state append and target commands use `0..` in the stable order returned by `handle`.

Before dispatch, Keiro checks `eventAlreadyIn`. If a concurrent writer wins after that check, `confirmBenignDuplicate` verifies that the colliding id really exists in the intended stream. The result records `PMStateDuplicate` or `PMCommandDuplicate` rather than appending twice.

Timer ids are caller-owned. Derive each `TimerRequest.timerId` deterministically from stable business facts—normally manager name, correlation id, source event id, and timer purpose—so a replay upserts the same timer row:

```haskell
-- CORRECT: a redelivery computes the same timer identity.
timerId = uuidV5 ("payment-timeout:" <> correlationId <> ":" <> sourceEventId)

-- WRONG: a redelivery creates a second deadline.
timerId <- randomUuid
```

The result of one reaction reports the manager append/duplicate, one `PMCommandResult` per target dispatch, and the number of timers scheduled. A real manager-state error returns `Left CommandError`; target failures stay inside `commandResults` for worker classification.

## Run Through The Worker Policy

`runProcessManagerWorkerWith` consumes a Shibuya `Adapter`, decodes each message to `(RecordedEvent, input)`, calls `runProcessManagerOnce`, and finalizes the message exactly once. Use `runProcessManagerWorker` only when the halt-first defaults are the standard you want.

`WorkerOptions` carries `poisonPolicy`, `rejectedCommandPolicy`, `transientRetryDelay`, and optional metrics. The defaults are `PoisonHalt`, `RejectedHalt`, a five-second retry delay, and no metric handle. Keep the two halt defaults until there is a durable dead-letter review and replay loop; otherwise acknowledging failure merely hides incomplete work.

The decision rules are:

- successful and duplicate work returns `AckOk`;
- a transient store or command error returns `AckRetry transientRetryDelay`;
- a systemic deterministic failure returns `AckHalt`;
- an undecodable input follows `PoisonPolicy`;
- an all-rejection group follows `RejectedCommandPolicy`.

`CommandAmbiguous` remains an aggregate-definition defect under the [command error standard](../keiro/command-cycle-and-errors.md). The fleet default is to halt and fix the transducer; never configure or generate an ambiguity outcome as successful firing.

At-least-once delivery is still bounded by the source adapter. With a Kiroku adapter, repeated `AckRetry` eventually records the source event in `kiroku.dead_letters` after the subscription retry ceiling. Install `kirokuEventBridge` to count that terminal transition, and query the durable table for current depth.

## Design Correlation For Either Arrival Order

Kiroku keeps events from one originating stream in append order and hashes one stream to one consumer-group member. Events from different streams that correlate to the same manager instance can race and can be handled by different members.

A manager joining `PaymentCaptured` from `payment-ORD1` with `ShipmentAllocated` from `shipment-ORD1` must accept either ordering. Record the first fact in saga state and wait for the second. Enforce a strict business sequence in the manager state machine, never by assuming global delivery order.

## Operate Durable Timers

A manager schedules a `TimerRequest` containing a stable `timerId`, manager name, correlation id, `fireAt`, and payload. If the manager state append commits, its timers commit with it.

`runTimerWorkerWith` requeues stale `Firing` rows according to `requeueStuckAfter`, claims the earliest due row with `FOR UPDATE SKIP LOCKED`, and calls the supplied fire action. Returning `Just eventId` marks the timer `Fired`; returning `Nothing` leaves it `Firing` until recovery requeues it.

Timer firing is at-least-once. A crash can happen after the external action but before `markTimerFired`, and a fire action running longer than the stale-claim window can be claimed again. The fire action must dispatch with a stable event id.

The default worker has no attempt ceiling and requeues stale claims after five minutes. In production, validate explicit options with `mkTimerWorkerOptions`. `maxAttempts = Just n` compares against the post-claim count: the `(n + 1)`th claim moves the timer to `Dead` without firing. Recovery tooling includes `countDueTimers`, `countStuckTimers`, `findStuckTimers`, `requeueStuckTimers`, `cancelTimer`, and `deadLetterTimer`.

## Keiro DSL Contract

Keiro-dsl has first-class `process` and nested `timer` nodes. A process declares rejected and poison policies, and every timer fire declares `on-ok`, `on-reject`, `on-ambiguous`, `on-error`, and `not-mine` outcomes. Keep reaction logic in the hand-owned hole and regenerate structural wiring from the specification; see [Keiro-dsl adoption](../keiro/dsl-adoption.md). Module placement belongs to the separate vertical-structure standard, not this behavior guide.

## The Decision Ladder

Start at the lowest rung that holds. Promote when the required behavior crosses a rung's boundary.

1. **Hand-rolled stateless reactor.** Use a plain Shibuya worker when the reaction has no per-correlation state and no deadline. It may join a read model for context. Danwa's `AddressedMessageWorker` is the model: it reacts only to relevant mention events, reads the message projection, derives a deterministic outbox id, and returns `AckRetry` while the projection has not caught up. Reactor plus read-model join plus retry-until-projected is the sanctioned shape for “react to X with context from Y.”
2. **Full Keiro `ProcessManager`.** Use it when the reaction depends on durable history for one correlation, needs a timeout or scheduled retry, or dispatches aggregate commands and benefits from deterministic ids and worker policy. Keiro's `FulfillmentProcess` and `EscalationProcess`, plus the generated HospitalSurge process in keiro-runtime-jitsurei, demonstrate this rung.
3. **Durable workflow.** Use `Keiro.Workflow` when the orchestration reads as one long-lived imperative sequence—do A, await B or sleep, then C, perhaps `continueAsNew`—rather than open-ended reactions to events. Follow the [durable workflow standard](../keiro/durable-workflows.md).

A reactor that accumulates state or hand-written deadline logic is a process manager wearing a costume—promote it.

## Related Patterns

- [Kiroku subscriptions](kiroku-subscriptions.md)
- [Transactional outbox](outbox.md)
- [Shibuya processing](shibuya-processing.md)
- [Messaging gotchas](gotchas.md)
- [Keiki transducer patterns](../keiki/overview.md)
