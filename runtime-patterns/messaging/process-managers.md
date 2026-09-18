---
type: Standard
title: "Process Managers And Durable Timers"
description: "The process manager standard: UTF-8-stable deterministic ids, the typed reaction runner, worker policies, batched durable timers, and the orchestration decision ladder"
timestamp: 2026-09-18T13:41:24Z
generated:
  by: process:codex
  at: "2026-09-18T13:41:24Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-process-managers
tags: [messaging, process-managers]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T18:19:01Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved shibuya 0.8.0.1, shibuya-{kafka,pgmq,kiroku,message-db} adapters, keiro 0.4.0.1, and kiroku source; changes requested: the standard pins itself to the released Keiro 0.3 boundary; 0.4.0.1 is the released line.
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T01:11:55Z
    document_timestamp: 2026-07-30T01:11:55Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction against the keiro changelog and tags: the standard now names the released 0.4 boundary.
  - kind: model
    reviewer: codex
    reviewed_at: 2026-09-18T13:31:31Z
    document_timestamp: 2026-09-18T13:01:11Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: openai
    model: gpt-6
    effort: unspecified
    context: >-
      Targeted timer-recovery review against mori://shinzui/keiro at 9fb54d56db4f, project-relative keiro/src/Keiro/Timer.hs (defaultTimerWorkerOptions, timerPassPreamble, claimAndFireOne); source artifact-level URI pending. The operator-only claim for interrupted Firing timers contradicts the default automatic requeue after 300 seconds and the earlier correct worker description in this document. Qualify manual recovery by worker policy and circumstances; do not describe all interrupted timers as non-retrying. Other sections were not exhaustively reverified.
  - kind: model
    reviewer: codex
    reviewed_at: 2026-09-18T13:41:24Z
    document_timestamp: 2026-09-18T13:41:24Z
    scope: technical-accuracy
    outcome: approved
    provider: openai
    model: gpt-6
    effort: unspecified
    context: >-
      Approved the targeted timer-recovery correction against mori://shinzui/keiro at 9fb54d56db4f: project-relative keiro/src/Keiro/Timer.hs (defaultTimerWorkerOptions, timerPassPreamble, claimAndFireOne); source artifact-level URI pending. Ordinary stale claims are automatically requeued under the configured policy, defaulting to 300 seconds; manual intervention and guarded resume recovery are distinguished. Other sections were not exhaustively reverified.
---

# Process Managers And Durable Timers

**Use an event-sourced saga for stateful orchestration, deterministic dispatch for crash recovery, and durable timers for deadlines.**

Use this standard when one service coordinates several events or aggregates over time. It defines the released Keiro process-manager boundary (current release 0.17.0.0, including typed transient store errors and the additive `Keiro.ProcessManager.Reaction` runner), its Shibuya worker policy, and the decision ladder between a small reactor, a full process manager, and a durable workflow.

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

The derivation now hashes UTF-8 seed bytes. ASCII identities are byte-identical to earlier releases. Non-ASCII seeds derive different ids, so a process-manager input retried across the upgrade can emit one duplicate command; keep target handling idempotent. The encoding and seed composition are frozen replay identity and must not change without a versioned adoption path.

Before dispatch, Keiro checks `eventAlreadyIn`. If a concurrent writer wins after that check, `confirmBenignDuplicate` verifies that the colliding id really exists in the intended stream. The result records `PMStateDuplicate` or `PMCommandDuplicate` rather than appending twice.

Timer ids are caller-owned. Derive each `TimerRequest.timerId` deterministically from stable business facts—normally manager name, correlation id, source event id, and timer purpose—so a replay upserts the same timer row:

```haskell
-- CORRECT: a redelivery computes the same timer identity.
timerId = uuidV5 ("payment-timeout:" <> correlationId <> ":" <> sourceEventId)

-- WRONG: a redelivery creates a second deadline.
timerId <- randomUuid
```

The result of one reaction reports the manager append/duplicate, one `PMCommandResult` per target dispatch, and the number of timers scheduled. A real manager-state error returns `Left CommandError`; target failures stay inside `commandResults` for worker classification.

## Use The Reaction Runner For Optional Advancement

`Keiro.ProcessManager.Reaction` is an additive runner beside the unchanged `ProcessManager` API. Choose it for new managers whose reaction may decline to advance saga state, or whose follow-ups must run only when the saga command durably accepts.

`react :: input -> ReactionPlan ci targetCi` returns one of:

- `NoAdvance followUps` — no saga read or command; unconditional timer follow-ups run in their own transaction;
- `AdvanceReaction { command, followUps, onAccepted }` — `followUps` run for every outcome, `onAccepted` only when this invocation appends saga events or recovers the exact accepted witness.

A `FollowUp` is `FollowDispatch`, `FollowSchedule Once|Rearm`, or `FollowCancel`. `Once` is insert-only while any row with the timer id exists; `Rearm` moves only a still-`Scheduled` row. Neither revives a `Firing`, `Fired`, `Cancelled`, `Dead`, or foreground-owned row. `FollowCancel` uses `Keiro.Timer.cancelTimerTx`, the transactional form of guarded cancellation; it cannot revoke a callback that already claimed the timer, so make late firing benign in the target.

Put every effect that must belong exclusively to durable acceptance in `onAccepted`. `NoAdvance`, a typed rejection, a no-op, and an eventless acceptance leave no saga receipt, so their unconditional effects may repeat on redelivery, including around a concurrent accepted delivery. The runner makes no exactly-once claim for silent outcomes.

The saga append and its timer subsequence commit in one transaction. Target commands then commit one transaction each, in declared attempt order; replay and concurrent delivery can make commit order differ from attempt order. Accepted redelivery validates the exact first-event witness in the intended saga stream, skips timer SQL, and retries only target fan-out. `ReactionWitnessMissing` and `ReactionWitnessUndecodable` are integrity errors: the worker halts on them rather than inventing a duplicate success.

Target commands use their own identity family, `deterministicReactionCommandId`: a length-prefixed UTF-8 UUIDv5 over `keiro`, `process-reaction`, manager name, correlation id, source event id, physical target stream, and the command's zero-based occurrence among commands to that target. Keep reaction inputs, same-target command order, and payloads stable for a source event.

Run it with `runReactiveProcessManagerOnce`, which returns detailed saga, timer, and target results, or `runReactiveProcessManagerWorkerWith`, which applies the same `WorkerOptions` poison, retry, rejection, and dead-letter policy as the classic worker while retaining only duplicate counts and failures.

**Switching an existing manager name to the reaction runner is an identity migration.** Drain source deliveries, incomplete fan-out, pending timers, and every permitted historical replay first. Otherwise a retained legacy saga witness enables dispatch under a new target id and duplicates the logical action. The same review applies to reordering same-target commands or changing their payloads. There is no positional-id fallback.

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

With Keiro 0.13 and Kiroku Store 0.8 or later, `TransientTransactionFailure` (`40001` or `40P01`) follows the transient `AckRetry` path for process managers and routers, including a wrapped `StoreFailed`. Extend custom classifiers and exhaustive store-error matches. The store can surface contention after its bounded retry; never treat that as proof of poisoned input or an impossible deadlock.

At-least-once delivery is still bounded by the source adapter. With a Kiroku adapter, repeated `AckRetry` eventually records the source event in `kiroku.dead_letters` after the subscription retry ceiling. Install `kirokuEventBridge` to count that terminal transition, and query the durable table for current depth.

## Design Correlation For Either Arrival Order

Kiroku keeps events from one originating stream in append order and hashes one stream to one consumer-group member. Events from different streams that correlate to the same manager instance can race and can be handled by different members.

A manager joining `PaymentCaptured` from `payment-ORD1` with `ShipmentAllocated` from `shipment-ORD1` must accept either ordering. Record the first fact in saga state and wait for the second. Enforce a strict business sequence in the manager state machine, never by assuming global delivery order.

## Operate Durable Timers

A manager schedules a `TimerRequest` containing a stable `timerId`, manager name, correlation id, `fireAt`, and payload. If the manager state append commits, its timers commit with it.

`runTimerWorkerWith` first returns expired guarded resume claims to `Dead`, then requeues stale `Firing` rows according to `requeueStuckAfter`, then claims the earliest due row with `FOR UPDATE SKIP LOCKED`, and calls the supplied fire action. Returning `Just eventId` marks the timer `Fired`; returning `Nothing` leaves it `Firing` until recovery requeues it.

Timer firing is at-least-once. A crash can happen after the external action but before `markTimerFired`, and a fire action running longer than the stale-claim window can be claimed again. The fire action must dispatch with a stable event id.

The default worker has no attempt ceiling and requeues stale claims after five minutes. In production, validate explicit options with `mkTimerWorkerOptions`. `maxAttempts = Just n` compares against the post-claim count: the `(n + 1)`th claim moves the timer to `Dead` without firing. `requeueStuckAfter = Nothing` disables only ordinary stale-claim requeue; since 0.16 every pass still recovers expired foreground resume claims. Recovery tooling includes `countDueTimers`, `countStuckTimers`, `findStuckTimers`, `requeueStuckTimers`, `cancelTimer`, `deadLetterTimer`, and read-only `lookupTimerInspection` and `findDeadTimers`.

Use `cancelTimerTx` to cancel inside the transaction that appends the event making a deadline obsolete. It applies the same guarded SQL as `cancelTimer`: an absent row creates no tombstone and terminal rows stay terminal.

`Dead` parks a timer; it is not proof the work is abandoned. Resume one only through the guarded claim protocol in [dead timer inspection and guarded resume](../keiro/dead-timer-resume.md). ID-only mutations — `markTimerFired`, `cancelTimer`, `cancelTimerTx`, `deadLetterTimer`, and stale requeue — refuse any row carrying a resume token, even after its lease expires. Migration `0032` adds those token columns; stop every old timer writer before applying it and deploy all upgraded writers before enabling resume.

Use `drainDueTimersWith` for a bounded backlog pass. It runs the requeue and gauge preamble once, then claims and fires up to the supplied limit with the same per-timer semantics as `runTimerWorkerWith`; do not drain a backlog one row per polling tick.

## Keiro DSL Contract

Keiro-dsl has first-class `process` and nested `timer` nodes. A process declares rejected and poison policies, and every timer fire declares `on-ok`, `on-reject`, `on-ambiguous`, `on-error`, and `not-mine` outcomes. In published Languages 1 through 5, keep reaction logic in the hand-owned hole (reported as `custom-unverified`) and regenerate structural wiring from the specification; see [Keiro-dsl adoption](../keiro/dsl-adoption.md).

Language 6 declares process reactions directly and generates them onto the reaction runner. Guards are pure, ordered, and read only the decoded input, never saga state. An `accepted` block is legal only when its saga command is verified to emit an event on acceptance, and it must carry an explicit `silent no-action` alternative; effects outside it become unconditional `followUps`, effects inside it `onAccepted`. The only create-once process hole is the versioned typed decoder `RecordedEvent -> Maybe <Process>Input`; it may decode but must not select or override behavior. Each reaction body declares a positive coordination version: a semantic change without a version increase is breaking, and any accepted change still requires the applicable drain. Versions and fingerprints never enter dispatch or timer identity. Module placement belongs to the separate vertical-structure standard, not this behavior guide.

## The Decision Ladder

Start at the lowest rung that holds. Promote when the required behavior crosses a rung's boundary.

1. **Hand-rolled stateless reactor.** Use a plain Shibuya worker when the reaction has no per-correlation state and no deadline. It may join a read model for context. Danwa's `AddressedMessageWorker` is the model: it reacts only to relevant mention events, reads the message projection, derives a deterministic outbox id, and returns `AckRetry` while the projection has not caught up. Reactor plus read-model join plus retry-until-projected is the sanctioned shape for “react to X with context from Y.”
2. **Full Keiro `ProcessManager`.** Use it when the reaction depends on durable history for one correlation, needs a timeout or scheduled retry, or dispatches aggregate commands and benefits from deterministic ids and worker policy. Keiro's `FulfillmentProcess` and `EscalationProcess`, plus the generated HospitalSurge process in keiro-runtime-jitsurei, demonstrate this rung. Use the reaction runner when advancement is optional or effects depend on acceptance.
3. **Durable workflow.** Use `Keiro.Workflow` when the orchestration reads as one long-lived imperative sequence—do A, await B or sleep, then C, perhaps `continueAsNew`—rather than open-ended reactions to events. Follow the [durable workflow standard](../keiro/durable-workflows.md).

A reactor that accumulates state or hand-written deadline logic is a process manager wearing a costume—promote it.

## Repair Stuck Timers By Classification

An ordinary timer left in `firing` by an interrupted worker is automatically requeued once it exceeds `requeueStuckAfter`; the default threshold is five minutes. Classify it manually when ordinary requeue is disabled, no worker is running, or repeated failures need intervention. Confirm the original firing action has stopped before manually requeueing. Guarded foreground claims follow the separate [resume recovery protocol](../keiro/dead-timer-resume.md). Use the [Keiro operations console](../keiro/operations-console.md): list candidates with `timer stuck list --min-age --min-attempts`, then requeue a transient failure, cancel obsolete work, or `dead-letter --reason` genuine poison. The reason is recorded with the `Dead` transition and is the literal a later [guarded resume](../keiro/dead-timer-resume.md) must match exactly, so write a stable one an on-call reader and a resuming consumer will both need. `timer drain-once --limit` is a bounded operator pass over the application's dispatch hook and never a substitute for running the timer worker.

## Related Patterns

- [Kiroku subscriptions](kiroku-subscriptions.md)
- [Keiro operations console](../keiro/operations-console.md)
- [Dead timer inspection and guarded resume](../keiro/dead-timer-resume.md)
- [Transactional outbox](outbox.md)
- [Shibuya processing](shibuya-processing.md)
- [Messaging gotchas](gotchas.md)
- [Keiki transducer patterns](../keiki/overview.md)
