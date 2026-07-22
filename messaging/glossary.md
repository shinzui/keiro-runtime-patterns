# Messaging Glossary

**The shared vocabulary for keiro messaging: one definition per term, linked everywhere, restated nowhere.**

Use this reference when reading or writing the messaging standards. These terms describe the contracts between Keiro, Kiroku, Shibuya, Kafka, and PGMQ; the linked guides carry the operational rules.

## Events And Boundaries

**Domain event.** A private, immutable fact recorded in one service's Kiroku event stream as a `RecordedEvent`. Its schema belongs to that service and may evolve with its internal model. Nothing outside the service may read its tables, event streams, or private event names.

**Integration event.** A stable, versioned public contract minted deliberately for another service. `Keiro.Integration.Event.IntegrationEvent` is the dependency-light envelope shared by producers and consumers. Never leak a domain event across a service boundary; map it to an integration event instead. See [Integration Events](integration-events.md).

**Envelope.** The transport-neutral metadata and payload carried with one message. Keiro's integration envelope owns public message identity and schema metadata. Shibuya's `Envelope` owns processing metadata such as message id, cursor, partition, delivery attempt, trace context, raw headers, and payload.

**Correlation id and causation id.** Correlation groups every event in one business process. Causation identifies the event that directly caused the current event. A process manager's `correlate` function derives the correlation key that selects its durable manager stream.

## Transactional Handoffs

**Outbox.** The pattern, backed by `keiro.keiro_outbox`, that records a decision to publish in PostgreSQL before a separate worker contacts the transport. This closes the loss window between local state and broker publication. See [Transactional Outbox](outbox.md).

**Inbox.** The mirror pattern, backed by `keiro.keiro_inbox`, that commits the consumer's local effect and deduplication row in one transaction. The default public-message identity is `(source, messageId)`. See [Transactional Inbox](inbox.md).

**At-least-once delivery plus idempotency.** Every transport in this stack can redeliver after a crash between the effect and its acknowledgement. Therefore every handler, finalizer, timer fire action, and publication retry path must be idempotent. This is the fleet's most load-bearing messaging invariant.

**Dead letter.** A durable record of a message or event that will not be retried automatically. Concrete homes include PGMQ dead-letter queues or archives, `kiroku.dead_letters` for subscription events, and `keiro.keiro_dead_letters` for Keiro dispatch failures. A dead-letter path is incomplete until an operator can inspect, repair, and deliberately replay or discard its contents.

## Orchestration

**Process manager, or saga.** A stateful coordinator implemented by `Keiro.ProcessManager`. It reacts to events, advances its own event-sourced state stream, dispatches deterministic commands, and can schedule durable timers. A router is stateless and resolves targets effectfully from a read model; a reactor is a hand-written stateless Shibuya worker; a durable workflow is an imperative long-running sequence. See [Process Managers And Durable Timers](process-managers.md) and the [Keiro runtime index](../keiro/README.md).

**Durable timer.** A `keiro.keiro_timers` row scheduled with manager state and claimed later by a timer worker. Timer firing is at-least-once, so the firing action must use a stable idempotency key.

## Shibuya Processing

**Adapter.** A Shibuya transport plug-in: `Adapter es msg` supplies a name, a stream of ingested messages, and a shutdown action. Adapters own broker-specific finalization mechanics.

**Message/ingested split.** `Ingested` is the framework-side value containing an envelope, an `AckHandle`, and an optional lease. Application handlers receive only the read-only `Message` projection, so they cannot acknowledge twice or forget to acknowledge; Shibuya owns finalization.

**Ack decision.** A handler's intent value: `AckOk`, `AckRetry RetryDelay`, `AckDeadLetter DeadLetterReason`, or `AckHalt HaltReason`. The handler chooses meaning and the adapter performs the broker-specific mechanics. See [Shibuya Processing](shibuya-processing.md).

**Poison message.** An input that fails deterministically on every delivery, such as malformed bytes or an unsupported payload. Every consumer must choose an explicit poison disposition; blind retry turns poison into a redelivery storm.

## Transport Terms

**Consumer group.** Several named consumers sharing one logical subscription. Work is partitioned among members while each member keeps a durable position; Kiroku hashes originating stream ids so one stream remains with one member.

**Checkpoint or cursor.** A durable or carried position showing how far a consumer has progressed. Broker coordinates are delivery metadata, not public business-message identity.

**Visibility timeout, or VT.** PGMQ's lease on an in-flight message. The message is invisible until the VT expires and is then eligible for redelivery. VT, not the handler's explicit retry delay, governs crash-redelivery cadence.

## Runtime Terms Live Elsewhere

Validated event streams, the Kiroku/Keiro/application schema ownership arrangement, snapshot semantics, and `CommandAmbiguous` are defined by the [Keiro runtime standards](../keiro/README.md). Messaging guidance links those definitions and does not redefine them.

## Related Patterns

- [Process managers and durable timers](process-managers.md)
- [Integration events](integration-events.md)
- [Shibuya processing](shibuya-processing.md)
- [Transport selection](transport-selection.md)

