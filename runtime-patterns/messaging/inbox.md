---
type: Standard
title: "Idempotent Inbox"
description: "Consuming integration events idempotently: runInboxTransaction variants, delegated downstream receipts, and disposition completeness"
timestamp: 2026-09-18T05:30:00Z
generated:
  by: process:claude-code
  at: "2026-09-18T05:30:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-inbox
tags: [messaging, inbox]
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

# Idempotent Inbox

**Commit a consumer's local effect and its deduplication record in one transaction — in `keiro_inbox` by default, or in one downstream event receipt when intake is delegated.**

At-least-once delivery means a handler will see duplicates. The inbox turns the stable integration identity into an at-most-once local effect within a defined retention window; it does not make the distributed system exactly once.

## Choose The Identity

Use `PreferIntegrationMessageId` by default. It records `(source, messageId)` and collapses broker redelivery and publisher retry. `PreferSourceEventIdentity` deliberately collapses public republishes derived from one private event. `KafkaDeliveryIdentity` identifies only one topic/partition/offset delivery and is a fallback, never the fleet default. Use `CustomDedupeKey` only when the contract requires a different collision-resistant identity. Keep a custom service-owned identity nominal and TypeID-backed under [domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md), converting to the inbox key representation only at this boundary.

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

## Delegate Only To A Complete Downstream Receipt

Table-backed intake is the default. Use delegated intake only when one downstream event receipt covers the complete protected operation; it then performs no `keiro_inbox` reads or writes and needs no `Store` effect.

- `runInboxDelegated`, `runInboxDelegatedWithRetries`, and `runInboxDelegatedBatch` compute the same dedupe key as the table runners and pass it to a handler returning `DelegatedOutcome` (`DelegatedFresh` or `DelegatedDuplicate`). That value is the handler's assertion; the wrapper cannot verify it.
- Build the handler from `Keiro.Inbox.Delegated`. `delegatedEventId` derives the version-1 receipt as a length-prefixed UTF-8 UUIDv5 over consumer, integration source, dedupe key, resolved target stream, and a stable operation name. `delegatedCommand` probes that id in the target stream before hydration, assigns it to the first event of exactly one atomic append, and accepts only a positive append or a confirmed replay in the same stream. Pass the prepared options it supplies to the command; all protected SQL, projection, and outbox work must commit in that append.
- `delegatedFromPMCommand` adapts one deterministic process-manager dispatch whose command identity already absorbs the intake identity. It does not prove a multi-command reaction completed.
- Handle every `DelegatedCommandError`. `DelegatedCommandFailed` and `DelegatedCommandWithoutReceipt` (a successful command that appended no event) are failures; never wrap the whole result as `DelegatedFresh`.

The caller owns durable attempt accounting: build `mkDelegatedRetryContext ceiling attempt` from a positive ceiling and the positive one-based current attempt, pass it to `runInboxDelegatedWithRetries`, and above the ceiling the handler is not invoked (`InboxPreviouslyFailed`). Durably publish or store a dead-letter record before acknowledging a terminal failure; the delegated wrappers write none. `runInboxDelegatedBatch` suppresses repeated identities only within its one sequential call.

Keep table intake for silent commands, zero-event successes, separately committed side effects, general workflow bodies, and multi-command reactions. Delegated consumers have no inbox backlog, failed-row, retention, or `keiro-ops inbox` surface. Renaming the marker event, target, consumer, source, or operation makes a replay look fresh.

Switching a consumer between table and delegated intake changes its persisted identity: inbox rows do not prove downstream receipts exist, and receipts do not populate inbox history. Drain in-flight delivery and fix an explicit cutover and replay boundary before switching in either direction. Candidate Language 6 expresses delegated intake as `idempotence delegated` (omission means `table`); it cannot be combined with `persist = dedupe-only`, and changing the mode is a breaking `IntakeIdempotenceModeChanged` diff. Measure before switching for speed: delegation makes confirmed duplicates much cheaper, but a fresh table batch can win through its shared commit.

## Define Every Disposition

Before shipping a consumer, decide all four paths, whichever intake mode it uses:

- fresh and valid: commit the local effect and acknowledge;
- duplicate: acknowledge without rerunning the effect;
- transient or in-progress: retry within an explicit ceiling;
- poison or previously failed: persist the failure with `markFailedTx`, dead-letter or halt according to the transport, and provide an operator replay path.

The Keiro DSL `intake` checker enforces a complete disposition table. Hand-written consumers must meet the same standard in review. Never let an undecodable message fall through to an unbounded retry loop.

## Operate The Inbox

Use `lookupInbox` and `listInbox` for inspection, `countInboxBacklog` or `sampleInboxBacklog` for monitoring, and `garbageCollectCompleted` for retention. The inbox also retains trace context so the consumer can continue the producer's trace.

Inspect and repair the same rows through the [Keiro operations console](../keiro/operations-console.md) rather than direct SQL: `inbox backlog|list|show` for state, `inbox gc` for retention, and `inbox mark-failed` for a deliberate decision never to process a message.

Completed-row retention defines the deduplication window. Once garbage collection removes a row, the same integration identity can run again; a concurrent cleanup can also shorten the effective window. Size retention beyond maximum expected redelivery and replay delay, and keep the handler's business effect idempotent even with an inbox.

## Related Patterns

- [Integration event contracts](integration-events.md)
- [Domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md)
- [Keiro operations console](../keiro/operations-console.md)
- [Transactional outbox](outbox.md)
- [Shibuya processing](shibuya-processing.md)
- [Messaging gotchas](gotchas.md)
