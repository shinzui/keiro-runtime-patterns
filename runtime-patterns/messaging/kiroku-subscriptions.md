---
type: Standard
title: "Kiroku Subscriptions Through Shibuya"
description: "Consuming the event log through the shibuya-kiroku bridge: ack-coupled checkpoints, guardKirokuHandler, consumer groups"
timestamp: 2026-07-22T11:25:02-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-kiroku-subscriptions
tags: [messaging, kiroku-subscriptions]
status: current
---

# Kiroku Subscriptions Through Shibuya

**Use the Kiroku adapter for ack-coupled reactions to a service's own event log.**

`kirokuAdapter` wraps `subscriptionAckStream` as `Adapter es RecordedEvent`. The Kiroku worker waits for each Shibuya finalization, so that decision controls durable checkpoint movement and provides natural backpressure.

## Map Acknowledgments Precisely

- `AckOk` becomes `Continue`: advance the checkpoint past the event.
- `AckRetry delay` becomes `Retry`: redeliver the same event before advancing. `RetryPolicy` bounds total deliveries; the default is five, then `DeadLetterMaxAttempts` is written.
- `AckDeadLetter reason` writes `kiroku.dead_letters` and atomically advances past the event.
- `AckHalt` cancels the subscription without advancing, so the event returns after restart.

`Envelope.attempt` is the zero-based redelivery count. The adapter's bridge queue may be larger, but ack coupling keeps effective in-flight delivery at one event per member.

## Guard Exceptions To Avoid A Spin

With Shibuya 0.8.0.1, the supervised runner catches a thrown handler and finalizes it as `AckRetry 0`; a bare handler does not leave the Kiroku reply unfilled. It can, however, retry immediately and create a hot loop. Prefer the adapter guard:

```haskell
-- CORRECT: thrown synchronous failures retry after one second.
mkProcessor adapter (guardKirokuHandler handler)

-- LEGAL BUT DANGEROUS: persistent throws become AckRetry 0.
mkProcessor adapter handler
```

`guardKirokuHandler` maps synchronous exceptions to `AckRetry 1`; asynchronous cancellation still escapes. `kirokuConsumerGroupProcessors` installs the guard automatically. Return explicit dead-letter or halt decisions for deterministic poison rather than spending all five deliveries.

## Scale With Consumer Groups

`kirokuConsumerGroupProcessors` creates N processors pinned to group-level `PartitionedInOrder` and member-level `Serial`. Kiroku hashes each originating stream in PostgreSQL to one member; events from that stream retain order while different streams run on different members. Each member checkpoints under `(subscriptionName, member)`.

Run all members in one process or assign one distinct member index per process. Exactly one live process should own an index. Events from different streams still have no global causal order, even if they share a process-manager correlation id.

## Configure And Observe The Subscription

Start from `defaultKirokuAdapterConfig` or `defaultConsumerGroupConfig`. Prefer an event category over `AllStreams` as the service grows; each process manager already has a `pm:<manager-name>` category. `eventTypeFilter` and `selector` run before the bridge, and the checkpoint advances past filtered events.

The default subscription retry policy allows five total deliveries. Delivery remains at-least-once and checkpointed per event through this adapter, so every handler effect must be idempotent.

Monitor `subscriptionStates`, but interpret it correctly: the map contains only live subscriptions. Stop, cancel, and crash remove the key; there is no durable `stopped` phase. Alert on a missing expected `(subscriptionName, member)`, not only on an unhealthy state value. Query `kiroku.dead_letters` for terminal failures; `kirokuEventBridge` increments its metric only when it observes Kiroku's terminal dead-letter event.

## Related Patterns

- [Process managers](process-managers.md)
- [Shibuya processing](shibuya-processing.md)
- [Transport selection](transport-selection.md)
- [Messaging gotchas](gotchas.md)
