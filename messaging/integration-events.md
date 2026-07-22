# Integration Event Contracts

**A domain event is private state; an integration event is a public, versioned contract.**

A service must not read another service's tables, Kiroku streams, or private event names. Cross a bounded-context boundary only through the published integration envelope and its payload contract.

## The Envelope

`Keiro.Integration.Event.IntegrationEvent` is the fleet contract:

- `messageId`: stable application identity for this published message;
- `source`: producing bounded context;
- `destination`: transport destination, conventionally including the contract major version;
- `key`: optional partition key, normally the aggregate id;
- `eventType` and `schemaVersion`: payload type and additive schema revision;
- `contentType`, `schemaReference`, and `payloadBytes`: encoding-neutral payload metadata and bytes;
- `sourceEventId` and `sourceGlobalPosition`: optional link to the private fact that caused publication;
- `occurredAt`, `causationId`, and `correlationId`: event time and causal chain;
- `traceContext`: W3C `traceparent` plus optional `tracestate`;
- `attributes`: optional contract metadata.

The envelope is byte-oriented. Use `ApplicationJson` and `encodeJsonIntegrationEvent` for the v1 JSON convention, but do not assume JSON in storage or consumers: `OtherContentType` and `SchemaReference` permit registry-backed formats without changing the outbox or inbox shape. Decode JSON with `decodeJsonIntegrationEvent`.

`integrationPayload` returns the wire body. `integrationHeaders` emits the `keiro-*` metadata headers plus W3C `traceparent` and `tracestate`; optional envelope fields produce optional headers.

## Identity And Evolution Rules

1. **Keep `messageId` stable across every delivery attempt.** `mintIntegrationEvent` creates a prefixed UUIDv7 TypeID. Once it is in an outbox row it survives publisher retries. If source-event redelivery can invoke mapping again, either make source checkpoint and enqueue one transaction or reuse a previously allocated stable `messageId` and `OutboxId`; calling `enqueueProducerEventTx` again mints a new message id.
2. **Deduplicate on `(source, messageId)`.** Kafka topic, partition, and offset are diagnostics for one broker delivery, not a logical-message identity. Repartitioning, replay, and republishing can change them.
3. **Put the contract major in `destination`.** Use names such as `billing.orders.v1`. A breaking payload change gets a new destination and runs beside the old one during migration.
4. **Use `schemaVersion` for additive evolution within one major destination.** Consumers must ignore unknown additive fields and explicitly reject versions they cannot interpret.
5. **Use `key` only for required ordering.** The usual key is an aggregate id. Same-key order also depends on the publisher's ordering policy and a serial-compatible consumer; `key` alone is not a global-order guarantee.
6. **Preserve causation and correlation.** Copy the causing event id into `causationId`, keep one business-flow id in `correlationId`, and carry source identity whenever the event derives from a private event.

One private event may fan out to several public contracts, each with its own `messageId`. Conversely, a consumer may deliberately choose source-event identity when it wants schema-upgrade republishes of one upstream fact to coalesce.

## Continue The Trace

Capture the producing trace in `TraceContext`. The outbox persists `traceparent` and `tracestate`, the transport carries them as headers, and the inbox persists them again. Start the consumer span with that remote parent; do not replace the cross-service trace with an unrelated root span.

## Related Patterns

- [Transactional outbox](outbox.md)
- [Idempotent inbox](inbox.md)
- [Messaging glossary](glossary.md)
- [Transport selection](transport-selection.md)
