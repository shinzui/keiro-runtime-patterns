---
type: Standard
title: "Kiroku Subscription Patterns"
description: "At-least-once subscriptions, per-batch checkpoints, overflow policies, and Serial consumer groups"
timestamp: 2026-07-22T16:52:58Z
generated:
  by: human:nadeem
  at: "2026-07-22T16:52:58Z"
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

Handlers return `Continue`, `Stop`, `Retry delay`, or `DeadLetter reason`. The default retry policy allows five total deliveries, including the first. A fifth `Retry` writes the event to `kiroku.dead_letters`, advances the checkpoint, and continues.

## Choose overflow behavior only where it applies

`queueCapacity` and `OverflowPolicy` apply only to non-group `AllStreams` subscriptions. Category and consumer-group subscriptions fetch directly from PostgreSQL and ignore them.

- `PauseAndResume` is the default and the only lossless queue policy. It pauses publisher delivery, drains stale queued work, then catches up again from the checkpoint.
- `DropSubscription` fails the slow subscriber.
- `DropOldest` continues after intentionally losing queued events.

Do not describe `PauseAndResume` as a universal subscription guarantee: it is lossless only on the publisher-backed, non-group `AllStreams` path.

## Run static consumer groups honestly

`ConsumerGroup { member, size }` defines a zero-based member of a fixed-size group. PostgreSQL hashes each originating stream to one member, preserving per-stream order without dynamic rebalance. Checkpoints are distinct for each `(subscriptionName, member)`. Resizing is a coordinated stop, drain, and restart because changing `size` reassigns streams.

For Shibuya, use `kirokuConsumerGroupProcessors`. It creates one processor per member and pins the group to `(PartitionedInOrder, Serial)`. Run one adapter per process with a distinct member when processes are separated; never invent parallel work inside a member.

Any Shibuya handler on the acknowledgement-coupled bridge must prevent synchronous exceptions from escaping. `guardKirokuHandler` turns such an exception into `AckRetry (RetryDelay 1)`, allowing Kiroku to finalize the acknowledgement. `kirokuConsumerGroupProcessors` applies this guard automatically.

## Alert on absence, not a stopped state

`subscriptionStates` and `currentState` contain only live workers. A stopped, cancelled, or crashed subscription is removed from the registry; the FSM never publishes `Stopped` into its live state cell. Alert when an expected `(name, member)` key is absent. Recover the terminal reason from `KirokuEventSubscriptionStopped` logs or metrics, not from a nonexistent `Stopped` entry.

The broader transport, process-manager, and messaging standards live in the messaging documentation area when that area is available.

## Related Patterns

- [Operational Invariants](./operational-invariants.md)
- [Observability](./observability.md)
- [Append and Read Patterns](./append-and-read.md)
