# Keiro Messaging Patterns

**How keiro services orchestrate internally and talk to each other: the standards index.**

Use this area for process managers, public integration contracts, transactional handoffs, and the Shibuya transports that carry asynchronous work. Start with the glossary, then follow the path matching the behavior you are building.

## Shared Vocabulary

- [Messaging glossary](glossary.md) — domain and integration events, outbox, inbox, acknowledgements, delivery, and transport terms.

## Orchestrating Inside A Service

- [Process managers and durable timers](process-managers.md) — saga state, deterministic dispatch, worker policies, timers, and the orchestration decision ladder.

## Talking To Other Services

- [Integration events](integration-events.md) — the public envelope, identity, versioning, ordering, and trace propagation contract.
- [Transactional outbox](outbox.md) — safely record and publish outbound integration events.
- [Idempotent inbox](inbox.md) — deduplicate inbound integration events with their local effects.

## The Processing Substrate

- [Shibuya processing](shibuya-processing.md) — acknowledgement intent, finalization, concurrency, batching, supervision, and shutdown.
- [Transport selection](transport-selection.md) — choose among PGMQ, Kafka, and Kiroku subscriptions.
- [Typed PGMQ jobs](pgmq-jobs.md) — background work, retry policy, visibility timeout, FIFO groups, and queue identity.
- [Kiroku subscriptions](kiroku-subscriptions.md) — consume a service's own event log through Shibuya.

## Before Production

- [Messaging gotchas](gotchas.md) — failure modes that must be addressed in design and operations.

## Related Patterns

- [Keiki transducer patterns](../keiki/README.md) — the durable state-machine layer under aggregates and manager streams.
- [Keiro runtime patterns](../keiro/README.md) — assembly, schemas, command errors, read models, workflows, telemetry, and DSL adoption.
