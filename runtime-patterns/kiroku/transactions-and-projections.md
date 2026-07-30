---
type: Standard
title: "Kiroku Transactions and Projections"
description: "Atomic append plus projection with runTransactionAppendingResource, and why the other combinators are traps"
timestamp: 2026-07-22T09:52:58-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-transactions-and-projections
tags: [kiroku, transactions-and-projections]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T09:52:58-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved kiroku-project checkout (kiroku-store, adapters, otel, metrics) and the keiro consumer's Connection API; verified exported symbols, signatures, version claims, and links.
---

# Kiroku Transactions and Projections

**Use `runTransactionAppendingResource` for atomic append-plus-projection work, and keep its continuation minimal.**

Use this guide when an event append and application SQL must commit or roll back together. It distinguishes the transaction surfaces, hook behavior, retry policy, and the store-wide lock held by an append.

## Use the resource-aware combinator

`runTransactionAppendingResource` is the fleet standard. It prepares and appends events, applies `StoreSettings.enrichEvent`, and runs a `Hasql.Transaction.Transaction` continuation in the same database transaction. The `NoRetry` sibling provides the same hook-aware shape without serialization retry.

```haskell
result <-
  runTransactionAppendingResource stream expected events $ \appendResult -> do
    updateProjection appendResult
    pure appendResult
```

The enrichment hook runs before encoding and before the transaction body. This is the seam used to inject OpenTelemetry trace context and other typed metadata. Bare `appendToStreamTx` and the non-resource `runTransactionAppending` variants cannot reach the live `KirokuStore`, so they bypass the hook. If a lower-level transaction is genuinely required, call `enrichEventsIO store events` before `prepareEventsIO` and `appendToStreamTx`.

## Know the transaction surfaces

- `runTransaction` and `runTransactionNoRetry` execute an arbitrary Hasql transaction.
- `appendToStreamTx` appends prepared events inside such a transaction and returns `Either AppendConflict AppendResult`; the caller must condemn the transaction if a conflict must roll everything back.
- `runTransactionAppending` and `runTransactionAppendingNoRetry` combine append and continuation but bypass event enrichment.
- `runTransactionAppendingResource` and `runTransactionAppendingResourceNoRetry` combine append, enrichment, and continuation and are the service-facing standard.

Prefer the highest-level surface that expresses the operation. The lower-level functions exist for unusual transaction shaping, not as interchangeable spellings.

## Minimize the `$all` lock interval

An append updates Kiroku’s global `$all` bookkeeping row. PostgreSQL holds that row lock until the surrounding transaction commits or rolls back, so the continuation blocks every other appender to the same store.

Use the continuation only for the bounded SQL needed to keep a projection, outbox, or other read-model row atomic with the event. Precompute inputs before entering it. Do not make HTTP calls, wait on another service, perform slow computation, or run unbounded per-row work while the lock is held.

## Choose retry behavior deliberately

The retrying `runTransaction*` variants may execute the entire body again after a serialization conflict. That is appropriate only when the body’s effects are wholly inside the database transaction. Use a `NoRetry` variant when the body has any externally observable behavior, or move that behavior behind a durable outbox so the transaction remains replay-safe.

## Related Patterns

- [Append and Read Patterns](./append-and-read.md)
- [Connection Settings](./connection-settings.md)
- [Observability](./observability.md)
