---
type: Standard
title: "Transactional Outbox"
description: "Transactional enqueue, publication failure and terminal rejection, atomic finalization, maintenance, and deterministic identity"
timestamp: 2026-09-18T05:30:00Z
generated:
  by: process:claude-code
  at: "2026-09-18T05:30:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-outbox
tags: [messaging, outbox]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T18:21:13Z
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

An `IntegrationProducer` gives a private-event mapper a stable name, source, message-ID namespace, and pure `mapEvent`. Construct it with `mkIntegrationProducer`, which rejects an empty namespace or one that fails TypeID prefix syntax. Map relevant `RecordedEvent` values to `IntegrationEventDraft`, and call `enqueueProducerEventTx producer recorded emissionIndex draft` inside the transaction owned by the application's subscription wiring. Use emission index `0` for a single-draft mapper; a fan-out mapper must assign each emission a stable index.

Producer identity is deterministic and versioned (Keiro ADR-42, `mori://shinzui/keiro/okf/adrs/concepts/ADR-42`). Version 1 hashes the producer source, producer name, source event UUID, and emission index; the `OutboxId` is a UUIDv8 from that digest and the `messageId` is the opaque text `<namespace>_v1_<sha256-hex>`. It is not a TypeID; never parse it as one. The same source event therefore yields the same identities on rollback, restart, and redelivery. Missing `sourceEventId` and `sourceGlobalPosition` default from the recorded event; explicit overrides are kept and compared. `deriveProducerIdentity` exposes the pure derivation.

`enqueueProducerEventTx` returns a `ProducerEnqueueOutcome` inside the transaction:

- `ProducerInserted` — a new row; it still rolls back with the surrounding transaction;
- `ProducerDuplicateIdentical` — a retained row has identical canonical content; nothing is updated, so publication status, attempts, and rejection audit survive the replay;
- `ProducerIdentityConflict identity fields` — a retained row under either identity differs. `fields` lists `ConflictField` classes only, never payload or metadata values.

Treat a conflict as mapper drift, not a duplicate. Call `Tx.condemn` in the transaction that also saves the checkpoint, so the cursor does not advance; after the transaction runner returns, call `recordProducerEnqueueOutcome metrics outcome` once to count it, then halt or dead-letter the source event rather than advancing past it. Keep observation outside SQL so serialization retries do not multiply the counter. Under repeatable-read or serializable isolation, retry serialization failures; the replay path takes a locking read through both unique indexes. The application still owns source consumption; `IntegrationProducer` is a producer definition and enqueue primitive, not a checkpoint-owning subscription runner.

Freeze the tuple. Renaming the producer source or name, or reassigning emission indices, is a new delivery identity that republishes under new IDs; changing only the namespace collides with the retained `OutboxId` and reports a conflict. Deduplication lasts only as long as the outbox row: after `garbageCollectSent` removes it, a replay republishes with the same wire `messageId`, and downstream inbox retention decides suppression. Size inbox retention to the replay horizon. A retained rejected row is never revived by producer replay. Payload comparison is byte-exact, attributes compare as canonical JSON, and `occurredAt` is truncated to whole microseconds before storage and comparison.

Adopting 0.17 on a producer that minted random IDs is a cutover. Historical TypeID message IDs cannot be derived from the new tuple. Drain in-flight attempts and keep committed checkpoints so pre-cutover events are not replayed, or supply an application-owned old-to-new mapping before any replay. No schema migration is required.

`freshIntegrationEvent` builds an explicitly fresh envelope with a random TypeID message ID and no provenance defaulting; `mintIntegrationEvent` is its deprecated alias. Use it only when the caller persists the envelope before any retry. `enqueueOutboxTx` collapses a repeated `(source, messageId)` with `ON CONFLICT ... DO NOTHING` without comparing content; reuse both the message identity and `OutboxId` for an idempotent retry through that path.

`Keiro.Outbox` re-exports `Keiro.Outbox.Identity`, whose records carry `outboxId`, `messageId`, and `sourceEventId`. Bare selector calls on those names can become ambiguous on upgrade; use record-dot syntax or qualify the import rather than hiding the identity module.

For a saga or process manager already inside a Keiro SQL transaction, use `enqueueIntegrationEventTx`. Supply a stable `OutboxId`; do not call `freshOutboxId` on every redelivery. Keep `OutboxId`, message IDs, and the service-owned IDs used to derive them as nominal types under [domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md); render a primitive only at the outbox boundary. Danwa's addressed-message reactor derives a UUIDv5 from stable business facts. This deliberately matches Keiro's `deterministicCommandId` recipe: namespace a deterministic UUID over the triggering fact and emitted purpose. That prescribed deterministic identity retains its UUIDv5 semantics; it is not relabelled as an allocated UUIDv7 entity ID.

## Preserve Required Order

The default `PerKeyHeadOfLine` claim policy blocks later non-terminal rows for the same source and key while allowing other keys to progress. `PerSourceStream` orders the whole source, `StopTheLine` halts after a failure, and `BestEffort` opts out of failure blocking.

Both per-key and per-source order use `created_at`, which PostgreSQL sets at transaction start. Two concurrent same-key inline transactions can commit in the reverse of those timestamps. Serialize same-key enqueues when strict order matters; otherwise the result is best-effort. Caller-owned producer wiring must provide the same serialization guarantee.

The publisher emits a row's stored `content_type` text unchanged. Only exact `application/json` reads back as `ApplicationJson`; every other stored value, including a non-canonical JSON spelling, is published verbatim as `OtherContentType`. Write the canonical form at enqueue.

## Publish Outside The Business Transaction

Run `publishClaimedOutbox` repeatedly. One pass claims rows with `FOR UPDATE SKIP LOCKED`, calls the supplied batch publisher, then maps `PublishSucceeded`, `PublishFailed`, and `PublishRejected` into sent, retryable/dead, or terminal rejected row states according to `OutboxPublishOptions`. Under ordered policies, a failed head blocks or skips its later group members without blocking unrelated keys.

The worker is transport-neutral. Keiro intentionally does not own an `hw-kafka-client` producer; `Keiro.Outbox.Kafka.outboxRowToKafkaRecord` and `integrationEventToKafkaRecord` only convert the contract. The application owns producer configuration and acknowledgment. Danwa demonstrates a one-second `pollingStream` tick that returns failed publishes to the outbox rather than dropping them.

Validate production options with `mkOutboxPublishOptions`. Defaults are a 32-row batch, ten attempts, two-second constant backoff, per-key head-of-line ordering, and a five-minute publishing timeout.

## Record permanent refusal as terminal audit evidence

Return `PublishRejected` only when publication is intentionally and permanently refused. Construct its abstract `PublishRejection` through `mkPublishRejection`: the code must match `^[a-z][a-z0-9._-]{0,63}$`, and optional detail must contain 1–1024 UTF-8 bytes. Validation does not normalize the input. Use stable codes; keep payloads and unbounded exception text out of the audit detail and telemetry labels.

A committed rejection becomes `OutboxRejected`, with `rejectedAt` and `rejection` on `OutboxRow`. It schedules no retry, releases successors under per-key and per-source ordering, and does not halt `StopTheLine`. A `PublishFailed` still blocks its later ordered group members; do not label a temporary outage as rejection to drain a queue. Extend exhaustive outcome/status matches and direct row, summary, and metrics construction.

The publisher finalizes sent, rejected, failed, and skipped rows in one transaction. Each update must still match `publishing`; stale claims cannot overwrite terminal truth. The `published`, `rejected`, `retried`, and `dead` fields of `OutboxPublishSummary`, and the corresponding metrics, count committed transitions rather than callback intentions. If finalization fails before commit, recovery may invoke the callback again: preserve the at-least-once publication contract and stable transport deduplication.

Low-level callers must also adopt the conditional results: `markOutboxFailedTx` returns `Maybe OutboxStatus`, `markOutboxSkippedTx` and `markOutboxRejectedTx` return `Bool`, and `markOutboxSentBatchTx` returns the changed count. A no-change result is not a newly committed outcome.

Apply Keiro migration `0031` before the upgraded runtime or console reads outbox rows. Upgrade every reader and publisher before enabling `PublishRejected`; older status decoders cannot interpret `rejected`. The migration constrains rejection audit columns and removes rejected rows from head-of-line indexes. `garbageCollectSent`, maintenance, backlog counts, and stuck-row recovery do not remove or retry rejected rows; retain their audit evidence under an explicit application policy.

## Run Maintenance Separately

Schedule `outboxMaintenancePass` less frequently than publishing. It reclaims stale `publishing` rows through `requeueStuckOutbox`, dead-letters rows that exhausted the attempt ceiling, and samples `countOutboxBacklog`.

Retention is a separate job: call `garbageCollectSent` on an explicit schedule and keep dead and rejected rows for operator review. `outboxMaintenancePass` does not garbage-collect sent rows.

For interactive repair, drive the same APIs through the [Keiro operations console](../keiro/operations-console.md): `outbox backlog|list|show` and `dead-letters list` to inspect, `requeue-stuck` for rows a crashed publisher stranded, `gc-sent` for retention, and `maintenance-pass` for one bounded default pass. Reclaiming stuck rows is not a remedy for a failing destination.

## Related Patterns

- [Integration event contracts](integration-events.md)
- [Domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md)
- [Keiro operations console](../keiro/operations-console.md)
- [Idempotent inbox](inbox.md)
- [Process managers](process-managers.md)
- [Messaging gotchas](gotchas.md)
