---
type: Pattern
title: "Transport Selection"
description: "Choosing a transport: the pgmq vs Kafka vs kiroku-subscription matrix and rule of thumb"
timestamp: 2026-07-22T11:27:32-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-transport-selection
tags: [messaging, transport-selection]
status: current
---

# Transport Selection

**PGMQ and Kafka carry queued work or messages between systems; the Kiroku adapter consumes a service's own event log and is not a cross-service transport.**

Choose the failure and ordering semantics first, then the adapter.

| Dimension | PGMQ | Kafka | Kiroku subscription |
|---|---|---|---|
| Payload | Aeson `Value` | `Maybe ByteString` | `RecordedEvent` |
| Delivery | At-least-once | At-least-once | At-least-once, ack-coupled |
| Lease / visibility timeout | Yes; extendable `Lease` | None | None |
| `Envelope.attempt` | Yes, from one-based `readCount` | Always `Nothing` | Yes, bounded by subscription `RetryPolicy` |
| Concurrency | `Serial`, `Ahead`, or `Async`; FIFO groups available | **`Serial` only; caller-enforced** | Consumer-group members `Serial`; group is `PartitionedInOrder` |
| Retry | Change visibility timeout | Seek partition to failed offset | Redeliver before checkpoint advance |
| Dead letters | Archive, direct queue, or topic route; adapter DLQ transfer is transactional | **No DLQ producer; warn and store offset** | Durable `kiroku.dead_letters` row plus checkpoint advance |
| Ordering | Per FIFO message group when grouped reads are configured | Per partition, provided processing is serial | Per originating stream within a consumer group |
| Configuration | Queue, VT, polls, attempts, DLQ, FIFO, prefetch | Topics in adapter; consumer properties outside | Subscription target/name, filters, buffering, optional group |

## Kafka Constraints Are Hard Constraints

Run the Kafka adapter with `Serial`. librdkafka stores the highest finalized offset per partition without gap tracking; `Ahead` or `Async` can store an offset after an earlier message requested retry, dead-letter, or halt. The adapter cannot inspect the processor policy, so runtime validation does not enforce this.

Kafka sets `Envelope.attempt` to `Nothing`; cap retries in an external durable store or halt. `AckDeadLetter` writes a loud stderr warning and stores the offset. It does not publish a DLQ record, so the group moves on and cannot recover that delivery from its committed position. Supply a DLQ producer if the message must remain recoverable.

Applications own Kafka on both sides. Keiro's `Keiro.Outbox.Kafka` and `Keiro.Inbox.Kafka` are pure contract codecs, not an `hw-kafka-client` runtime.

## PGMQ Constraints Are Database Constraints

PGMQ provides an attempt count, visibility timeout, lease extension, retry caps, transactional adapter DLQ transfer, and per-group FIFO reads without a separate broker. It also shares PostgreSQL capacity and failure domains. A visibility-timeout expiry increments `readCount` even when no handler returned `AckRetry`; size VT above worst-case processing or extend the lease.

Adapter `maxRetries = 0` is technically valid and dead-letters a first delivery before its handler. Prefer Keiro's validated `mkRetryPolicy` for jobs.

## Kiroku Is For Private Event Reactions

Use the Kiroku adapter for projections, reactors, and process managers driven by a service's private event store. Its acknowledgment controls the durable event-log checkpoint. Do not expose a Kiroku stream as another bounded context's integration API.

## Rule Of Thumb

**PGMQ for in-context jobs and anything needing DLQ, retry caps, leases, or ordered groups without a broker; Kafka for cross-context event streaming where a cluster exists and you can guarantee serial consumption and supply your own DLQ/retry bookkeeping.**

Use Kiroku subscriptions only for reactions to the local event log.

Keiro currently ships Kafka codecs for integration outbox and inbox boundaries. PGMQ as an integration-event transport is roadmap status, not scheduled. If that case is implemented, build it on `Keiro.PGMQ.Runtime`, never on the background-job `Keiro.PGMQ.Job` abstraction.

The durable rationale for this choice is recorded in [ADR 0003](https://github.com/shinzui/keiro-runtime-patterns/blob/master/docs/adr/0003-pgmq-vs-kafka-transport-selection.md).

## Related Patterns

- [Shibuya processing](shibuya-processing.md)
- [PGMQ jobs](pgmq-jobs.md)
- [Kiroku subscriptions](kiroku-subscriptions.md)
- [Integration event contracts](integration-events.md)
