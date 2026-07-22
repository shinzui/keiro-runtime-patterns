# Idempotent Inbox

**Commit a consumer's local effect and its deduplication record in one transaction.**

At-least-once delivery means a handler will see duplicates. The inbox turns the stable integration identity into an at-most-once local effect within a defined retention window; it does not make the distributed system exactly once.

## Choose The Identity

Use `PreferIntegrationMessageId` by default. It records `(source, messageId)` and collapses broker redelivery and publisher retry. `PreferSourceEventIdentity` deliberately collapses public republishes derived from one private event. `KafkaDeliveryIdentity` identifies only one topic/partition/offset delivery and is a fallback, never the fleet default. Use `CustomDedupeKey` only when the contract requires a different collision-resistant identity.

Kafka delivery coordinates remain useful diagnostics and are persisted in `KafkaDeliveryRef`; they are not a substitute for a stable application identity.

## Use One Of The Seven Exported Runners

`Keiro.Inbox` exports seven transactional entry points:

- `runInboxTransaction`: default full-envelope persistence and caller-selected policy;
- `runInboxTransactionWith`: selects `PersistFullEnvelope` or `PersistDedupeOnly`;
- `runInboxTransactionWithKey`: supplies the source and dedupe key directly;
- `runInboxTransactionWithRetries`: adds bounded failed-attempt handling;
- `runInboxTransactionWithRetriesWith`: combines retry handling and persistence choice;
- `runInboxTransactionWithRetriesKey`: combines retry handling and a direct key;
- `runInboxTransactionBatch`: processes a batch transactionally, then falls back per message if the fast path throws or is condemned.

The `...KeyPersist` helpers in the module body are internal and are not part of the public API.

Each runner inserts a completed inbox row and runs the supplied `Hasql.Transaction` handler in the same database transaction. A duplicate returns `InboxDuplicate` without rerunning the effect. A throw or `Tx.condemn` rolls back both the effect and fresh row. Retrying variants record thrown-handler failures separately and stop invoking the handler at the configured attempt ceiling.

`PersistDedupeOnly` reduces successful-row payload storage but retains identity, routing, occurrence time, and delivery correlation. Failure rows keep the full envelope for operator review.

## Define Every Disposition

Before shipping a consumer, decide all four paths:

- fresh and valid: commit the local effect and acknowledge;
- duplicate: acknowledge without rerunning the effect;
- transient or in-progress: retry within an explicit ceiling;
- poison or previously failed: persist the failure with `markFailedTx`, dead-letter or halt according to the transport, and provide an operator replay path.

The Keiro DSL `intake` checker enforces a complete disposition table. Hand-written consumers must meet the same standard in review. Never let an undecodable message fall through to an unbounded retry loop.

## Operate The Inbox

Use `lookupInbox` and `listInbox` for inspection, `countInboxBacklog` or `sampleInboxBacklog` for monitoring, and `garbageCollectCompleted` for retention. The inbox also retains trace context so the consumer can continue the producer's trace.

Completed-row retention defines the deduplication window. Once garbage collection removes a row, the same integration identity can run again; a concurrent cleanup can also shorten the effective window. Size retention beyond maximum expected redelivery and replay delay, and keep the handler's business effect idempotent even with an inbox.

## Related Patterns

- [Integration event contracts](integration-events.md)
- [Transactional outbox](outbox.md)
- [Shibuya processing](shibuya-processing.md)
- [Messaging gotchas](gotchas.md)
