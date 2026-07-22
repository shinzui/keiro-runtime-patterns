# Kiroku Operational Invariants

**Treat these ten rules as production invariants, not optional tuning advice.**

Use this runbook when reviewing, deploying, or diagnosing any Kiroku-backed service. Each invariant links to the focused pattern that explains its API and rationale.

## 1. Migrate before opening the store

Apply the complete pg-migrate plan before `withStore`. Store acquisition starts pools, `LISTEN`, and publisher infrastructure but performs no DDL. See [Connection Settings](./connection-settings.md).

## 2. Keep the schema authoritative

Use the fleet schema `kiroku` for both tables and the `<schema>.events` notification channel, and grant the runtime role the required schema and table privileges. A runtime schema override without a matching migration is invalid. See [Connection Settings](./connection-settings.md).

## 3. Preserve search-path order

Keep Kiroku first, explicitly listed application or framework schemas next, and `pg_catalog` last. Keiro services normally use `kiroku, keiro, pg_catalog`; never depend on implicit `public`. See [Connection Settings](./connection-settings.md).

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

