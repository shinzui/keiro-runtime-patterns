# ADR 0003: Select PGMQ and Kafka by failure semantics

## Status

Accepted — 2026-07-22

## Context

The service fleet uses Shibuya over two queue transports plus an event-log bridge. PGMQ provides PostgreSQL-backed queues for operational work. Kafka provides cross-context event streaming. The Kiroku adapter consumes one service's private event log. Treating these as interchangeable hides materially different retry, ordering, lease, dead-letter, and operational contracts.

About twenty services need one selection rule that preserves those contracts and does not design against deferred framework work.

## Decision

Use PGMQ for in-context jobs and work needing a DLQ, retry caps, visibility leases, or ordered groups without a separate broker. Use Kafka for cross-context event streaming when a cluster exists and the application can guarantee serial consumption and supply its own DLQ and retry bookkeeping. Use Kiroku subscriptions only for reactions to the local event log.

Keiro integration events use the outbox and inbox contracts with the current Kafka codecs. PGMQ as an integration-event transport remains unscheduled roadmap work. If implemented, it must build on `Keiro.PGMQ.Runtime`, not the background-job `Keiro.PGMQ.Job` abstraction.

## Consequences

- Kafka consumers accept the adapter's `Serial`-only caller contract, absent attempt counter, and lack of a built-in DLQ producer. Applications own the Kafka producer and consumer around Keiro's pure codecs.
- PGMQ jobs share PostgreSQL capacity and failure domains, and operators must size visibility timeout above handler runtime. The supervised adapter's configured DLQ transfer is transactional; Keiro's one-shot drain remains at-least-once across its separate send and delete effects.
- Kiroku checkpoints remain private implementation mechanics. Other bounded contexts consume published integration events, never another service's streams or tables.
- A future Kafka-free integration-event path requires deliberate framework work for PGMQ codecs, fan-out bindings, and inbox/outbox wiring; current job APIs are not a substitute.

## Alternatives Considered

**Kafka everywhere.** Rejected because background jobs would inherit broker operations while still lacking adapter-level attempt counts, leases, and recoverable dead letters.

**PGMQ everywhere now.** Rejected because Keiro's PGMQ integration-event transport and fan-out wiring are roadmap status, not a released contract. Modeling public events as jobs would conflate durable facts with transient work.

**Treat Kiroku subscriptions as a cross-service bus.** Rejected because it exposes private event-store schemas and checkpoints across bounded contexts.

## Related Guidance

- [Transport selection](../../messaging/transport-selection.md)
- [Typed PGMQ jobs](../../messaging/pgmq-jobs.md)
- [Integration event contracts](../../messaging/integration-events.md)
- [Kiroku subscriptions](../../messaging/kiroku-subscriptions.md)
