---
type: Runbook
title: "Kiroku Operational Invariants"
description: "The ten invariants every kiroku-backed service must respect in production"
timestamp: 2026-07-30T01:11:55Z
generated:
  by: human:nadeem
  at: "2026-07-30T01:11:55Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-operational-invariants
tags: [kiroku, operational-invariants]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T16:52:58Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved kiroku-project checkout (kiroku-store, adapters, otel, metrics) and the keiro consumer's Connection API; changes requested: the normative search path wrongly includes the keiro schema.
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T01:11:55Z
    document_timestamp: 2026-07-30T01:11:55Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction against keiro's Connection API: the normative search path now excludes the keiro schema.
---

# Kiroku Operational Invariants

**Treat these ten rules as production invariants, not optional tuning advice.**

Use this runbook when reviewing, deploying, or diagnosing any Kiroku-backed service. Each invariant links to the focused pattern that explains its API and rationale.

## 1. Migrate before opening the store

Apply the complete pg-migrate plan before `withStore`. Store acquisition starts pools, `LISTEN`, and publisher infrastructure but performs no DDL. See [Connection Settings](./connection-settings.md).

## 2. Keep the schema authoritative

Use the fleet schema `kiroku` for both tables and the `<schema>.events` notification channel, and grant the runtime role the required schema and table privileges. A runtime schema override without a matching migration is invalid. See [Connection Settings](./connection-settings.md).

## 3. Preserve search-path order

Keep Kiroku first, explicitly listed application schemas next, and `pg_catalog` last. Keiro services normally use `kiroku, <application projection schema>, pg_catalog`; the `keiro` framework schema stays out of the search path because Keiro's runtime SQL is fully qualified and `keiroConnectionSettings` deliberately does not add it. Never depend on implicit `public`. See [Connection Settings](./connection-settings.md).

## 4. Bound database resource use

Start with `poolSize = 10`, `idleInTransactionTimeout = 30`, and the production override `statementTimeout = Just 30`. Change them only from measured workload evidence. See [Connection Settings](./connection-settings.md).

## 5. Preserve append identity and concurrency

Use the strictest honest `ExpectedVersion`, preserve a supplied `eventId` across retries, and treat the matching `DuplicateEvent` as completion. The third field of `WrongExpectedVersion` is always zero; explicitly re-read with `getStream`. See [Append and Read Patterns](./append-and-read.md).

## 6. Know every retry boundary

Direct append retries serialization and deadlock failures once. Retrying transaction combinators may rerun their whole body; use `NoRetry` for externally visible effects. Subscription retry permits five total deliveries before dead-lettering. Notifier reconnection backs off 1, 2, 4, 8, 16, then 30 seconds, while publisher and category paths retain a 30-second safety poll. See [Transactions and Projections](./transactions-and-projections.md) and [Subscriptions](./subscriptions.md).

## 7. Make subscription handling idempotent

Delivery is at least once and checkpointing is per batch. Use `withSubscription`. Queue capacity and overflow policy affect only non-group `AllStreams`; only `PauseAndResume` on that path is lossless. See [Subscriptions](./subscriptions.md).

## 8. Keep callbacks synchronous and fast

`eventHandler` and `observationHandler` run on the emitting thread. Update in-memory state or enqueue into a bounded buffer; never block those callbacks on network exporters. See [Observability](./observability.md).

## 9. Treat global positions as opaque

`GlobalPosition` is a strictly increasing total-order cursor, not a dense counter. Persist returned positions and compare them; never manufacture the next one with arithmetic. See [Append and Read Patterns](./append-and-read.md).

## 10. Put authorization around erasure

The hard-delete GUC is an accident guard, not a security boundary. Deny `DELETE` to the normal application role, use a separately authorized path, and append an application event recording who decided what, why, and when before physical deletion. See [Lifecycle and Deletion](./lifecycle-and-deletion.md).

## Related Patterns

- [Append and Read Patterns](./append-and-read.md)
- [Subscriptions](./subscriptions.md)
- [Lifecycle and Deletion](./lifecycle-and-deletion.md)
