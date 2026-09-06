---
type: Gotcha
title: "Messaging Gotchas"
description: "Consolidated messaging gotcha catalogue across Shibuya, pgmq-hs 0.5, Kafka, Kiroku, and Keiro"
timestamp: 2026-09-06T21:22:15Z
generated:
  by: process:codex
  at: "2026-09-06T21:22:15Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-gotchas
tags: [messaging, gotchas]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T18:27:32Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved shibuya 0.8.0.1, shibuya-{kafka,pgmq,kiroku,message-db} adapters, keiro 0.4.0.1, and kiroku source; verified exported symbols, signatures, version claims, and links.
---

# Messaging Gotchas

**Twenty-one ways the messaging stack will bite you, and the rule that prevents each.**

Treat these as design-review checks, not trivia.

1. **Kafka dead letters are dropped from the consumer group's recoverable path.** The adapter has no DLQ producer: `AckDeadLetter` warns on stderr and stores the offset. Wire a durable DLQ publisher or do not use dead-letter acknowledgment on Kafka. See [transport selection](transport-selection.md).

2. **Run the Kafka adapter with `Serial`; nothing enforces it.** `Ahead` or `Async` can store a later offset after an earlier delivery failed because librdkafka has no gap-tracking commit layer here. See [Shibuya processing](shibuya-processing.md).

3. **Kafka never supplies `Envelope.attempt`.** It is always `Nothing`, so retry-by-count needs external durable bookkeeping or an `AckHalt` policy. See [transport selection](transport-selection.md).

4. **PGMQ crash redelivery follows visibility timeout, not retry delay.** Every VT expiry increments `read_ct` toward the attempt ceiling. Put VT above worst-case handler time or extend the lease. See [PGMQ jobs](pgmq-jobs.md).

5. **Raw PGMQ `maxRetries = 0` skips every handler.** First delivery already has `readCount = 1`, so the adapter dead-letters it immediately. Construct job policies with `mkRetryPolicy`. See [PGMQ jobs](pgmq-jobs.md).

6. **Know which PGMQ DLQ boundary you use.** The supervised adapter's direct/topic DLQ send plus source delete is transactional in `shibuya-pgmq-adapter` 0.14.0.0; Keiro's `runJobOnce*` sends and deletes separately, so a crash can leave both copies. Keep one-shot handlers idempotent and reconcile duplicates. See [PGMQ jobs](pgmq-jobs.md).

7. **PGMQ prefetch can delay messages after shutdown.** It does not lose them; buffered, undispatched messages reappear only after VT. Keep `bufferSize * batchSize * average processing time` below visibility timeout. See [PGMQ jobs](pgmq-jobs.md).

8. **Finalizers must be idempotent.** Shibuya retries the same decision after 10 ms, 50 ms, and 250 ms when finalization throws, then halts the processor. See [Shibuya processing](shibuya-processing.md).

9. **A throwing handler becomes `AckRetry 0`.** An always-throwing handler can produce an immediate redelivery storm. Decode, validate, and convert expected poison or permanent failures to explicit decisions. See [Shibuya processing](shibuya-processing.md).

10. **Guard Kiroku handlers to avoid zero-delay spins.** On Shibuya 0.9.0.0 a throw is finalized, so it does not block forever; `guardKirokuHandler` improves the fallback from `AckRetry 0` to `AckRetry 1`, and group helpers install it automatically. See [Kiroku subscriptions](kiroku-subscriptions.md).

11. **Do not validate a dead-letter code per message.** `mkDeadLetterCode` is a startup-time gate; calling it inside a handler turns a naming mistake into a per-delivery failure on the exact path that is already failing. Validate the finite code set once and keep it in configuration. See [Shibuya processing](shibuya-processing.md).

11. **PGMQ worker envelopes do not expose arbitrary headers.** JSONB headers are unordered, so the continuous adapter sets `Envelope.headers = Nothing`; raw headers are available only in the one-shot `JobContext`. See [PGMQ jobs](pgmq-jobs.md).

12. **`QueueRef` sanitization is lossy.** `a.b` and `a_b` collide, long or `_dlq`-ending names are hashed, and a rename can point workers at a new empty queue while messages remain in the old one. Freeze logical names and drain before migration. See [PGMQ jobs](pgmq-jobs.md).

13. **PGMQ retries only a statement-error whitelist.** In pgmq-hs 0.5, `Pgmq.Effectful.isTransient` retries acquisition, networking, connection-session failures, SQLSTATE 40001, 40P01, 55P03, 57P01/02/03, and class 53. Authentication, compatibility, decode/row-count, script, missing-type, driver, and every other statement failure are permanent. See [PGMQ queue lifecycle](pgmq-queue-reconciliation.md).

14. **`CommandAmbiguous` is never success.** Multiple matching edges are an aggregate-definition defect; process-manager workers halt, and the DSL rejects an ambiguity outcome of `Fired`. See [process managers](process-managers.md) and the [command error standard](../keiro/command-cycle-and-errors.md).

15. **Schema-qualify framework SQL.** Kiroku keeps the event store and LISTEN/NOTIFY contract in `kiroku`; Keiro owns `keiro.keiro_outbox`, `keiro.keiro_inbox`, `keiro.keiro_timers`, and `keiro.keiro_dead_letters`; application projections have a separate owner. Bare `keiro_*` names depend on the wrong search-path assumption. See the [schema arrangement](../keiro/two-schema-arrangement.md).

16. **Keiro supplies messaging contracts and primitives, not complete broker wiring.** Applications own the Kafka producer and consumer around `Keiro.Outbox.Kafka` and `Keiro.Inbox.Kafka`. `IntegrationProducer` also does not own a source checkpoint, and `enqueueProducerEventTx` mints a fresh message ID per call; make checkpoint plus enqueue atomic or reuse stable message and outbox identities. See [transactional outbox](outbox.md).

17. **Transactional Keiro runners require `KirokuStoreResource`.** `runCommandWithSql`, `runCommandWithSqlEvents`, and `runCommandWithProjections` need the resource acquired with `withKirokuStore`; plain `runCommand` does not. The outbox and inbox transactional continuations live inside the same resource-backed boundary. See [runtime assembly](../keiro/runtime-assembly.md).

18. **Keep transactional continuations minimal.** An appending transaction retains Kiroku's global `$all` row lock until commit. Slow outbox mapping, inline projections, timer scheduling, or unrelated SQL inside that window stalls every writer. See [transactional outbox](outbox.md) and [process managers](process-managers.md).

19. **PGMQ reconciliation is additive, not destructive repair.** A queue-type mismatch reports `DetectedQueueTypeDrift` and preserves the queue; partition interval and retention are not checked at all. Fail startup and resolve the drift deliberately. See [PGMQ queue lifecycle](pgmq-queue-reconciliation.md).

20. **A visibility-timeout update can lose a race.** `changeVisibilityTimeout` and `setVisibilityTimeoutAt` return `Nothing` when the row was already deleted, archived, or popped. Settle that as a lost race rather than retrying it as infrastructure failure. See [PGMQ queue lifecycle](pgmq-queue-reconciliation.md).

21. **PGMQ notifications are hints.** They are fire-and-forget and throttled, and the missing throttle means 250 ms. Use `notifyChannelName`, keep a poll fallback, and install the 0.5 native migration component for crash-safe notification recovery and serialized enablement. See [PGMQ queue lifecycle](pgmq-queue-reconciliation.md).

**Terminal publication rejection releases ordering.** `PublishRejected` is durable audit truth, does not retry, and does not stop `StopTheLine`. Keep temporary broker failures on `PublishFailed`, retain rejected rows, and install migration `0031` before deploying the new readers. See [transactional outbox](outbox.md).

## Related Patterns

- [Messaging standards index](overview.md)
- [Shibuya processing](shibuya-processing.md)
- [Transport selection](transport-selection.md)
- [Keiro gotchas](../keiro/gotchas.md)
- [PGMQ queue lifecycle and reconciliation](pgmq-queue-reconciliation.md)
