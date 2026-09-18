---
type: Standard
title: "Integration Event Contracts"
description: "The integration event contract: envelope, identity and dedupe rules, topic versioning, trace continuation"
timestamp: 2026-09-18T04:30:00Z
generated:
  by: process:claude-code
  at: "2026-09-18T04:30:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-integration-events
tags: [messaging, integration-events]
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

# Integration Event Contracts

**A domain event is private state; an integration event is a public, versioned contract.**

A service must not read another service's tables, Kiroku streams, or private event names. Cross a bounded-context boundary only through the published integration envelope and its payload contract.

## The Envelope

`Keiro.Integration.Event.IntegrationEvent` is the fleet contract:

- `messageId`: stable, opaque application identity for this published message;
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

Text and bytes in the envelope are boundary representations. In service-owned payload and application types, follow [domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md): keep IDs TypeID-backed and keep every key scalar nominal, then encode or decode the primitive form at the contract boundary. A language-version-4 contract field that carries an ID is declared `typeid "prefix"`, not `Text`.

`integrationPayload` returns the wire body. `integrationHeaders` emits the `keiro-*` metadata headers plus W3C `traceparent` and `tracestate`; optional envelope fields produce optional headers.

## Identity And Evolution Rules

1. **Keep `messageId` stable across every delivery attempt and every remapping.** Treat it as opaque text, never as a parseable TypeID or a time-ordered UUID. The canonical producer path, `enqueueProducerEventTx`, derives it deterministically from the producer and source-event coordinates as `<namespace>_v1_<sha256-hex>`, so remapping the same private event after rollback or redelivery yields the same identity and a changed mapping surfaces as `ProducerIdentityConflict`. `freshIntegrationEvent` (formerly `mintIntegrationEvent`, now deprecated) generates a random identity: persist that envelope before any retry and reuse it. See [transactional outbox](outbox.md).
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
- [Domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md)
- [Idempotent inbox](inbox.md)
- [Messaging glossary](glossary.md)
- [Transport selection](transport-selection.md)
