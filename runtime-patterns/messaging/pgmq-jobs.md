---
type: Standard
title: "Typed Background Jobs On PGMQ"
description: "Typed background jobs on keiro-pgmq 0.17: required job ordering, FIFO-heads, retry and VT rules, guarded DLQ retention, and partitioned provisioning"
timestamp: 2026-09-18T13:01:11Z
generated:
  by: process:codex
  at: "2026-09-18T13:01:11Z"
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
  , jobOrdering :: JobOrdering
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

Build non-default tuning with `mkJobTuning`, then apply the job's own ordering with `withOrdering job.jobOrdering`. Keiro-pgmq 0.17 checks every consumer before it builds an adapter or issues a read, including one assembled from raw `Job` and `JobTuning` constructors, and throws `JobConsumptionConfigError` on invalid tuning (`InvalidJobTuning`), on tuning whose ordering differs from the job's (`JobOrderingMismatch`), or on a legacy FIFO batch larger than one (`UnsafeLegacyFifoBatch`). `jobProcessor` and `runJobOnce` inherit `jobOrdering` automatically.

## Declare Ordering On The Job

**Every `Job` declares `jobOrdering`; choose `FifoHeads` whenever per-group order must survive failures and retries.**

- `Unordered`: approximate `msg_id` selection order, no per-key guarantee. The default for independent work.
- `FifoHeads`: PGMQ grouped-head reads. A read leases at most the absolute oldest message of each `x-pgmq-group`; an invisible, delayed, or failed head blocks only its own group while other groups stay eligible. `batchSize` bounds how many groups one read claims, not how many members it takes from a group. Requires PGMQ 1.12 or later and `shibuya-pgmq-adapter` 0.16 (`HeadPerGroup`). Keiro handlers remain serial.
- `FifoThroughput` and `FifoRoundRobin`: the legacy fill strategies (`read_grouped`, `read_grouped_rr`). They can lease a successor before its predecessor settles, so Keiro accepts them only with a batch size of one. Do not select them for new jobs.

Roll `FifoHeads` out consumers first: migrate the schema to PGMQ 1.12 or later, deploy every consumer built with the required `jobOrdering` and `FifoHeads` support, and only then change the generated queue policy or producer assumptions. Never leave an older consumer reading an ordered queue as unordered or through a legacy batch-filling read.

Messages without an `x-pgmq-group` header share one implicit group. Grouped reads are visibility leases, not exactly-once delivery; handlers stay idempotent. A `.keiro` `ordering fifo-heads` declaration scaffolds `FifoHeads` and FIFO-index provisioning under Language 6; see [language versions](../keiro/language-versions.md).

## Produce And Consume

Use `enqueue` for ordinary work, `enqueueWithHeaders` for JSON metadata, and `enqueueTraced` to inject the active trace. Batch variants reduce round trips. Use `enqueueToGroup` or `enqueueToGroupWithDelay` on a `FifoHeads` job for strict send order within one `x-pgmq-group` while independent groups proceed separately.

`jobProcessor` builds a default Shibuya processor; `jobProcessorWithContext` adds lease extension, attempt, and headers to the handler. The continuous worker path exposes `JobContext.headers = Nothing` because the adapter does not flatten unordered JSONB into Shibuya's ordered, duplicate-preserving header type. The one-shot path exposes the raw JSON header object.

Use `runJobWorkers` for supervised continuous service workers. Use `runJobOnce` or `runJobOnceWithContext` for bounded CLI or scheduled drains. Provision at startup with `ensureJobQueue`; it reconciles the main queue and optional DLQ idempotently through pgmq-config. Use `ensureOrderedJobQueue` for ordered jobs; it adds PGMQ's conventional FIFO GIN index on `headers`. Its presence does not prove the planner uses it for grouped-read expressions, and Keiro recommends no supplemental index; measure before adding one. Treat every reconciliation action as operational evidence and apply the [PGMQ queue lifecycle and reconciliation](pgmq-queue-reconciliation.md) standard.

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

## Size Partition Retention Above The Worst Outage

`partitionedProvision` is experimental and needs a `pg_partman`-enabled server. Retention is not per-message expiry: maintenance drops whole old partitions of the active queue and its archive without checking whether a message was processed. Set retention above the worst expected consumer outage plus backlog age, with a margin.

Build the spec with `mkPartitionSpec`, which trims input and returns `PartitionSpecConfigError` for empty, non-positive, mixed-unit, out-of-`INTEGER`-range, or retention-shorter-than-span numeric values before any database access. It does not prove a safe horizon. Keiro provisions with `premake = Nothing`, keeping the server's default of four premade partitions; explicit premake is available only through `pgmq-config` on PGMQ 1.13. See [PGMQ queue lifecycle](pgmq-queue-reconciliation.md).

## Freeze Queue Identity

`queueRef` lowercases and sanitizes a logical name. This mapping is deliberately lossy: `a.b` and `a_b` address the same physical queue. A sanitized base longer than 43 characters, or one ending in `_dlq`, becomes its first 26 characters plus a 16-hex FNV-1a-64 suffix; the sibling DLQ then fits PGMQ's 47-character ceiling.

Treat logical queue and job names as durable identifiers. Renaming can point new workers at an empty physical queue while the old queue still contains messages. Check collisions before launch and drain before a rename.

At the lower pgmq-hs boundary, every physical `QueueName` is validated as non-empty, at most 47 characters, and lowercase ASCII letters, digits, or underscore. Do not add another normalizer around it. Before crossing pgmq-hs 0.5, remediate historical mixed-case metadata with the upstream transactional runbook; never hand-edit `pgmq.meta`.

## Know Which DLQ Path You Run

The supervised worker delegates direct-queue or topic-route dead-lettering to `shibuya-pgmq-adapter` (0.16.0.0 for Keiro 0.17), which sends the DLQ row and deletes the source row in one database transaction. With no configured DLQ it archives the source row.

Every DLQ payload it writes carries three reason fields: the compatibility `dead_letter_reason` string, the machine-queryable `dead_letter_reason_code`, and an always-present `dead_letter_reason_detail` that encodes as JSON `null` for a reason with no detail. Query and alert on the code; the adapter transports application-owned codes and details verbatim through Shibuya's public projections and no longer renders constructors itself. See [Shibuya processing](shibuya-processing.md).

The `runJobOnce*` implementation sends to the job DLQ and then deletes the main row as separate effects. A crash between them can leave both copies. Keep handlers idempotent and give one-shot drains reconciliation tooling.

## Retain Dead Letters Before Purging

`readDlq`, `redriveDlq`, and count-based `archiveDlq` read visible rows and hide each inspected row for 30 seconds. `DlqEntry.originalHeaders` exposes the producer headers preserved in the wrapper.

- **Archive what you inspected by id.** Keep each `dlqMessageId` and pass the list to `archiveDlqEntries`; it moves rows even while inspection hides them and returns only the ids actually moved. Compare the returned set with the requested set before treating retention as complete.
- **Handle `PurgeDlqBlocked`.** `purgeDlq` returns `PurgeDlqResult`: `PurgeDlqPurged n`, or `PurgeDlqBlocked hidden` when a metrics snapshot shows hidden rows. Never discard the result. The snapshot and delete are not atomic; for a full-queue audit, quiesce producers and other operators, archive every row that needs retention, confirm active depth is zero, and only then purge. A bounded read followed by purge still deletes uninspected visible rows.
- **Reserve `purgeDlqForce`.** It deletes every active row, hidden ones included. Use it only as a deliberate escape hatch.
- **Redrive restores the original headers.** The FIFO group, trace, and application headers return with the payload; a legacy wrapper with missing or JSON-null headers is redriven headerless, never with the DLQ row's own headers. A redriven message gets a new id, a fresh `read_ct`, and the back of its group. Redrive is at-least-once: a crash between send and delete leaves both copies.

Operate a job DLQ through the [Keiro operations console](../keiro/operations-console.md): `pgmq dlq read` decodes entries, `redrive` returns them to the main queue once the cause is fixed, and `archive` retains evidence where `purge` destroys it. A forced console purge uses the guarded `purgeDlq` and fails without deleting when rows are hidden.

PGMQ integration events are a separate, deferred transport concern. A future implementation must use `Keiro.PGMQ.Runtime`; do not model integration contracts as `Job` values.

## Related Patterns

- [Transport selection](transport-selection.md)
- [Keiro operations console](../keiro/operations-console.md)
- [Shibuya processing](shibuya-processing.md)
- [Messaging gotchas](gotchas.md)
- [PGMQ queue lifecycle and reconciliation](pgmq-queue-reconciliation.md)
