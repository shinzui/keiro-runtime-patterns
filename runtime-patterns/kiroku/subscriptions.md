---
type: Standard
title: "Kiroku Subscription Patterns"
description: "At-least-once subscriptions, explicit first-run checkpoint intent, durable checkpoint inventory, overflow policies, and Serial consumer groups"
timestamp: 2026-10-14T22:02:59Z
generated:
  by: process:codex
  at: "2026-10-14T22:02:59Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-subscriptions
tags: [kiroku, subscriptions]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T16:52:58Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved kiroku-project checkout (kiroku-store, adapters, otel, metrics) and the keiro consumer's Connection API; verified exported symbols, signatures, version claims, and links.
---

# Kiroku Subscription Patterns

**Run subscriptions with `withSubscription`, make handlers idempotent, and use the adapter’s Serial consumer-group processors.**

Use this guide for Kiroku background consumers and their Shibuya bridge. It covers delivery, checkpoints, retry, overflow, static partitioning, lifecycle, and alerting.

## Design for at-least-once delivery

Kiroku delivers events at least once and advances checkpoints per batch. A crash after handling an event but before saving the batch checkpoint redelivers the last batch. Every handler must therefore be idempotent, usually through a projection key, inbox row, or natural upsert.

Prefer `withSubscription` to bare `subscribe`. The bracketed API cancels the worker on normal exit and exceptions, preventing a thread from outliving its effect environment.

Handlers return `Continue`, `Stop`, `Retry delay`, or `DeadLetter reason`. `Stop` saves the stopping event position before exit; it is not a way to park an unhandled event for replay. The Shibuya bridge implements `AckHalt` by cancellation instead. The default retry policy allows five total deliveries, including the first. A fifth `Retry` writes the event to `kiroku.dead_letters`, advances the checkpoint, and continues.

## Decide what a missing checkpoint means

A missing checkpoint is a deployment decision, not ordinary worker state. Kiroku Store 0.5 makes that decision explicit through `MissingCheckpointPolicy` on `SubscriptionConfig`. The policy applies only when the exact `(SubscriptionName, consumer-group member)` row is absent; an existing durable row always wins and is never moved by startup initialization.

For every subscription, record one intended first-run policy in the runtime inventory:

- `FromBeginning` for replayable, idempotent derivations that require all retained history; it atomically materializes position zero;
- `FromCurrentHead` for intentionally future-only processing; it atomically materializes the current `$all` store head; or
- `FailIfMissing` when an operator must resolve ambiguity before startup; it returns a typed refusal without inserting a row.

Choose the policy in the same reviewed inventory that owns the subscription name. Changing the policy affects the next startup only when the exact row is absent; it does not rewind, fast-forward, rename, or delete an existing checkpoint. `initializeSubscriptionCheckpoint` exposes the same atomic resolution for explicit startup orchestration. Coordinated rebuild code may deliberately rewind existing member rows only through `resetSubscriptionCheckpointsTx`, which composes with the caller's transaction and reports the exact member keys reset. Do not issue private SQL against Kiroku's subscription table, synthesize group members, delete checkpoints, or treat the reset API as permission for arbitrary forward movement. The owning contract is `mori://shinzui/kiroku/plans/70-make-subscription-checkpoint-initialization-and-reset-semantics-explicit`.

`subscriptionCheckpointInventory`, introduced in Kiroku Store 0.4, remains the read-only observation surface. It returns the captured store position and every durable member-aware checkpoint in one snapshot, including rows whose workers are stopped. Inventory does not initialize or reset anything; use the explicit 0.5 policy and mutation APIs for those statements. An out-of-process reader gets the frozen `kiroku.subscription_checkpoints_v1` relation instead of either. See [durable checkpoint inventory](checkpoint-inventory.md).

## Choose overflow behavior only where it applies

`queueCapacity` and `OverflowPolicy` apply only to non-group `AllStreams` subscriptions. Category and consumer-group subscriptions fetch directly from PostgreSQL and ignore them.

- `PauseAndResume` is the default and the only lossless queue policy. It pauses publisher delivery, drains stale queued work, then catches up again from the checkpoint.
- `DropSubscription` fails the slow subscriber.
- `DropOldest` continues after intentionally losing queued events.

For a low-level publisher consumer, use `subscribePublisherWith` to observe the dropped-batch counter and call its idempotent `unsubscribe` on every exit. Treat a counter increase as a recovery boundary, not successful delivery. Publisher queues now carry `DecodedBatch`; preserve typed undecodable entries for explicit disposition rather than silently discarding them. Complete `Subscriber` records must supply `subDropped`.

Do not describe `PauseAndResume` as a universal subscription guarantee: it is lossless only on the publisher-backed, non-group `AllStreams` path.

## Run static consumer groups honestly

Construct the opaque `ConsumerGroupSize` with `mkConsumerGroupSize`, then each zero-based `ConsumerGroup` with `mkConsumerGroup`. Use `mkBatchSize` for positive catch-up batches and `mkStreamBufferSize` for positive acknowledgement-bridge buffers. Start configurations from their defaults; do not reconstruct private constructors. A member belongs to a fixed-size group. PostgreSQL hashes each originating stream to one member, preserving per-stream order without dynamic rebalance. Checkpoints are distinct for each `(subscriptionName, member)`. Stop every member before changing size or hash assignment. Call `resizeConsumerGroupTx` to lock the checkpoint set, equalize every new member at the old minimum checkpoint, remove obsolete members, and preserve target bindings in one transaction. A missing group starts at zero. Equalize even for a same-size hash-assignment change; replay is expected, so retain idempotent handlers. Never resize by editing checkpoint rows privately.

For Shibuya, use `kirokuConsumerGroupProcessors`. It creates one processor per member and pins the group to `(PartitionedInOrder, Serial)`. Run one adapter per process with a distinct member when processes are separated; never invent parallel work inside a member.

Use `kirokuProcessor` for a single Shibuya processor: it supplies the serial, unordered defaults and the one-second synchronous exception guard. `kirokuConsumerGroupProcessors` applies the same guard. A bare supervised handler exception becomes an immediate retry; pacing prevents a hot loop. Asynchronous cancellation remains cancellation. Raw bridge consumers must finalize every item or the worker waits indefinitely.

## Alert on absence, not a stopped state

`subscriptionStates` and `currentState` contain only live workers. A stopped, cancelled, or crashed subscription is removed from the registry; the FSM never publishes `Stopped` into its live state cell. Alert when an expected `(name, member)` key is absent. Recover the terminal reason from `KirokuEventSubscriptionStopped` logs or metrics, not from a nonexistent `Stopped` entry.

The broader transport, process-manager, and messaging standards live in the messaging documentation area when that area is available.

## Bind durable progress to its target

Require the Store 0.11 / migrations 0.7.1 cohort and apply the [ordered migration cutover](../migrations/operations.md#upgrade-the-kiroku-store-in-order). Startup checks stored group size and subscription target before delivery. Treat `SomeSubscriptionStartupFailure` as a typed configuration refusal, including missing checkpoints, topology or target mismatch, guard conflict, and invalid stall-warning intervals; do not retry it as transient database contention.

Choose `targetBindingPolicy` deliberately. `AdoptUnbound` is the default and binds legacy rows to the requested target; use it only after confirming what those rows consumed. `RequireBound` refuses legacy unbound rows. Existing bound rows cannot silently switch from `AllStreams` to a category or between categories. Stop all workers, then use `rebindSubscriptionTargetTx` with an explicit target and position to change that authority atomically. A missing subscription refuses; resize preserves the existing binding.

## Handle undecodable events without skipping history

Return `Either DecodeFailure RecordedEvent` from `StoreSettings.decodeHook`; wrap successful transformations in `Right`. Direct reads return `EventDecodeFailed` with no partial result. Hook exceptions remain programming failures; they are not typed data refusals.

With no `undecodableHandler`, a subscription retries a typed decode failure at one-second spacing under its retry bound, then stops with `SubscriptionUndecodable` / `StopUndecodable`, preserving the checkpoint before that event. Repair the hook and restart. Install an explicit callback only when skip (`Continue`), stop after checkpointing that event (`Stop`), retry, or durable `DeadLetterDecodeFailure` is the reviewed policy. A callback-selected exhausted `Retry` follows ordinary max-attempt dead-lettering; it does not use the default stop-before-undecodable behavior. Each publisher subscriber owns its disposition independently.

Set `handlerStallWarnAfter` only to a positive interval when advisory stall events are needed. The default `Nothing` adds no diagnostic tracking. A warning never acknowledges, retries, cancels, or advances progress; it cannot rescue a raw acknowledgement left pending.

## Related Patterns

- [Operational Invariants](./operational-invariants.md)
- [Replay-History Retention](./history-retention.md)
- [Observability](./observability.md)
- [Durable Checkpoint Inventory](./checkpoint-inventory.md)
- [Append and Read Patterns](./append-and-read.md)
