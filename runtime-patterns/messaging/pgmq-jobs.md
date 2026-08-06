---
type: Standard
title: "Typed Background Jobs On PGMQ"
description: "Typed background jobs on keiro-pgmq: Job, JobOutcome, RetryPolicy, VT rules, queue-name pitfalls"
timestamp: 2026-08-06T02:47:25Z
generated:
  by: human:nadeem
  at: "2026-08-06T02:47:25Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-pgmq-jobs
tags: [messaging, pgmq-jobs]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T18:25:02Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved shibuya 0.8.0.1, shibuya-{kafka,pgmq,kiroku,message-db} adapters, keiro 0.4.0.1, and kiroku source; verified exported symbols, signatures, version claims, and links.
---

# Typed Background Jobs On PGMQ

**Use `keiro-pgmq` for transient background work that would be misleading as a domain event.**

Thumbnail generation, notification delivery, and summary generation are jobs. A completed or retried job is operational work, not an immutable business fact for other bounded contexts.

## Declare The Job

```haskell
data Job p = Job
  { jobName :: Text
  , jobQueue :: QueueRef
  , jobCodec :: JobCodec p
  , jobPolicy :: RetryPolicy
  }

data JobOutcome
  = Done
  | Retry RetryDelay
  | RetryDefault
  | Dead Text
```

Job code never handles Shibuya wire values. `Done` deletes, `Retry` chooses a delay, `RetryDefault` uses the policy delay, and `Dead` supplies a poison reason.

Always construct policy with `mkRetryPolicy`. The raw `RetryPolicy` constructor accepts `maxRetries <= 0`; because PGMQ increments `read_ct` to 1 on first read and the adapter tests `readCount > maxRetries`, zero dead-letters every message before its handler. The validated constructor requires at least one delivery and a non-negative default delay.

Build non-default tuning with `mkJobTuning`, then select `FifoThroughput` or `FifoRoundRobin` through `withOrdering` when per-group order is required.

## Produce And Consume

Use `enqueue` for ordinary work, `enqueueWithHeaders` for JSON metadata, and `enqueueTraced` to inject the active trace. Batch variants reduce round trips. Use `enqueueToGroup` or `enqueueToGroupWithDelay` with ordered tuning for strict send order within one `x-pgmq-group` while independent groups proceed separately.

`jobProcessor` builds a default Shibuya processor; `jobProcessorWithContext` adds lease extension, attempt, and headers to the handler. The continuous worker path exposes `JobContext.headers = Nothing` because the adapter does not flatten unordered JSONB into Shibuya's ordered, duplicate-preserving header type. The one-shot path exposes the raw JSON header object.

Use `runJobWorkers` for supervised continuous service workers. Use `runJobOnce` or `runJobOnceWithContext` for bounded CLI or scheduled drains. Provision at startup with `ensureJobQueue`; it reconciles the main queue and optional DLQ idempotently through pgmq-config. Use `ensureOrderedJobQueue` when grouped reads need the FIFO index.

## Set Visibility Timeout From Runtime, Not Hope

The visibility timeout controls crash and slow-handler redelivery. `RetryPolicy.defaultRetryDelay` controls only explicit `RetryDefault`; it does nothing after a process dies. Every VT expiry consumes another `read_ct` delivery and can exhaust `maxRetries` before the handler returns.

Set VT comfortably above worst-case handler time, or use `JobContext.extendLease` before it expires. For adapter prefetch, keep:

```text
bufferSize * batchSize * average processing time < visibility timeout
```

On shutdown, prefetched but undispatched messages are not lost; they remain invisible until VT expires and are then redelivered. Expect delay, not deletion.

## Do Not Read The Descriptive pgmq Spec Clauses As Configuration

A `.keiro` pgmq dispatch node accepts a `fanout body` function name and a top-level dedupe key. Both are **descriptive-only**: `check` verifies the reference is well-formed and nothing more. Neither configures runtime behavior, and no runtime reads them. The same holds for timer dead-letter text.

Configure fanout and deduplication in the runtime, as this standard describes. If a spec clause is the only place a behavior is stated, that behavior does not exist. See [Keiro-dsl adoption](../keiro/dsl-adoption.md) for the wider set of accepted-but-inert surfaces Keiro 0.11 started warning about.

## Freeze Queue Identity

`queueRef` lowercases and sanitizes a logical name. This mapping is deliberately lossy: `a.b` and `a_b` address the same physical queue. A sanitized base longer than 43 characters, or one ending in `_dlq`, becomes its first 26 characters plus a 16-hex FNV-1a-64 suffix; the sibling DLQ then fits PGMQ's 47-character ceiling.

Treat logical queue and job names as durable identifiers. Renaming can point new workers at an empty physical queue while the old queue still contains messages. Check collisions before launch and drain before a rename.

## Know Which DLQ Path You Run

The supervised worker delegates direct-queue or topic-route dead-lettering to shibuya-pgmq-adapter, which sends the DLQ row and deletes the source row in one database transaction. With no configured DLQ it archives the source row.

The `runJobOnce*` implementation sends to the job DLQ and then deletes the main row as separate effects. A crash between them can leave both copies. Keep handlers idempotent and give one-shot drains reconciliation tooling.

PGMQ integration events are a separate, deferred transport concern. A future implementation must use `Keiro.PGMQ.Runtime`; do not model integration contracts as `Job` values.

## Related Patterns

- [Transport selection](transport-selection.md)
- [Shibuya processing](shibuya-processing.md)
- [Messaging gotchas](gotchas.md)
