---
type: Standard
title: "Transactional Outbox"
description: "Publishing through the transactional outbox: IntegrationProducer, publisher worker, maintenance pass, deterministic ids"
timestamp: 2026-07-22T11:21:13-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-outbox
tags: [messaging, outbox]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T11:21:13-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved shibuya 0.8.0.1, shibuya-{kafka,pgmq,kiroku,message-db} adapters, keiro 0.4.0.1, and kiroku source; verified exported symbols, signatures, version claims, and links.
---

# Transactional Outbox

**Never publish to a broker from a command handler or projection. Commit the decision to publish as an outbox row beside the local state that caused it.**

The outbox separates a durable local decision from an unreliable network publish. It has three independently operated parts: enqueue, publish, and maintenance.

## Enqueue The Decision

An `IntegrationProducer` gives a private-event mapper a stable name, source, TypeID prefix, and pure `mapEvent`. Construct it with `mkIntegrationProducer`, map relevant `RecordedEvent` values to `IntegrationEventDraft`, and use `enqueueProducerEventTx` inside the transaction owned by the application's subscription wiring.

That API is a producer definition and enqueue primitive, not a checkpoint-owning subscription runner. The application still owns source consumption and its at-least-once boundary. `enqueueProducerEventTx` mints a new `messageId` on every invocation, so do not assume a stable `OutboxId` alone makes an independently replayed call idempotent. Use one of these complete designs:

- advance the source checkpoint and run `enqueueProducerEventTx` in the same transaction; or
- persist or derive stable message and outbox identities, build the envelope with `draftToEvent`, and call `enqueueOutboxTx` with the same identities on replay.

`enqueueOutboxTx` collapses a repeated `(source, messageId)` with `ON CONFLICT ... DO NOTHING`. Reuse both the message identity and `OutboxId` for an idempotent retry.

For a saga or process manager already inside a Keiro SQL transaction, use `enqueueIntegrationEventTx`. Supply a stable `OutboxId`; do not call `freshOutboxId` on every redelivery. Danwa's addressed-message reactor derives a UUIDv5 from stable business facts. This deliberately matches Keiro's `deterministicCommandId` recipe: namespace a deterministic UUID over the triggering fact and emitted purpose.

## Preserve Required Order

The default `PerKeyHeadOfLine` claim policy blocks later non-terminal rows for the same source and key while allowing other keys to progress. `PerSourceStream` orders the whole source, `StopTheLine` halts after a failure, and `BestEffort` opts out of failure blocking.

Both per-key and per-source order use `created_at`, which PostgreSQL sets at transaction start. Two concurrent same-key inline transactions can commit in the reverse of those timestamps. Serialize same-key enqueues when strict order matters; otherwise the result is best-effort. Caller-owned producer wiring must provide the same serialization guarantee.

## Publish Outside The Business Transaction

Run `publishClaimedOutbox` repeatedly. One pass claims rows with `FOR UPDATE SKIP LOCKED`, calls the supplied batch publisher, then maps `PublishSucceeded` and `PublishFailed` into sent, retryable, or dead row states according to `OutboxPublishOptions`. Under ordered policies, a failed head blocks or skips its later group members without blocking unrelated keys.

The worker is transport-neutral. Keiro intentionally does not own an `hw-kafka-client` producer; `Keiro.Outbox.Kafka.outboxRowToKafkaRecord` and `integrationEventToKafkaRecord` only convert the contract. The application owns producer configuration and acknowledgment. Danwa demonstrates a one-second `pollingStream` tick that returns failed publishes to the outbox rather than dropping them.

Validate production options with `mkOutboxPublishOptions`. Defaults are a 32-row batch, ten attempts, two-second constant backoff, per-key head-of-line ordering, and a five-minute publishing timeout.

## Run Maintenance Separately

Schedule `outboxMaintenancePass` less frequently than publishing. It reclaims stale `publishing` rows through `requeueStuckOutbox`, dead-letters rows that exhausted the attempt ceiling, and samples `countOutboxBacklog`.

Retention is a separate job: call `garbageCollectSent` on an explicit schedule and keep dead rows for operator review. `outboxMaintenancePass` does not garbage-collect sent rows.

## Related Patterns

- [Integration event contracts](integration-events.md)
- [Idempotent inbox](inbox.md)
- [Process managers](process-managers.md)
- [Messaging gotchas](gotchas.md)
