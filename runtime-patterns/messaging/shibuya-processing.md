---
type: Guide
title: "Shibuya Processing Semantics"
description: "Shibuya processing semantics every worker inherits: ack decisions, application dead-letter codes, retries, batching, supervision, shutdown"
timestamp: 2026-10-14T22:02:59Z
generated:
  by: process:codex
  at: "2026-10-14T22:02:59Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-shibuya-processing
tags: [messaging, shibuya-processing]
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

# Shibuya Processing Semantics

**Handlers express intent with `AckDecision`; Shibuya owns finalization, retries, supervision, backpressure, and tracing mechanics.**

Every Keiro worker inherits these rules, regardless of its adapter.

## Keep Acknowledgment Framework-Owned

The application surface is:

```haskell
type Handler es msg = Message es msg -> Eff es AckDecision
```

A handler receives a read-only `Message` containing an `Envelope` and optional `Lease`. The adapter's `AckHandle` exists only on the framework-side `Ingested` value. Handler code therefore cannot acknowledge twice or forget to acknowledge; the runner resolves and finalizes one decision per delivery.

Return exactly the intent you mean:

- `AckOk`: processing succeeded;
- `AckRetry (RetryDelay d)`: redeliver after the adapter-specific delay mechanism;
- `AckDeadLetter (PoisonPill reason | InvalidPayload reason | MaxRetriesExceeded | ApplicationFailure code detail)`: permanently dispose through the adapter's dead-letter behavior;
- `AckHalt (HaltOrderedStream reason | HaltFatal reason)`: stop this processor without advancing the failed delivery.

Core Shibuya has no universal retry counter or dead-letter store. The adapter determines what retry, dead-letter, and halt do, so transport selection is part of failure semantics.

## Give a policy rejection its own dead-letter code

`ApplicationFailure` (Shibuya 0.9) is for a syntactically valid message that application policy permanently rejects — not a parse failure and not exhausted retries. Its `DeadLetterCode` constructor is private: **validate a finite set of codes once at startup with `mkDeadLetterCode`, keep the results in configuration, and reuse them in handlers.** Validating on every message turns a naming mistake into a per-delivery failure.

A valid code is at most 128 ASCII characters with at least two dot-separated segments, each matching `[a-z][a-z0-9_]*`. The first segment `shibuya` is reserved for framework-owned codes, so an application code can never collide with a built-in one.

Consume reasons through the total projections rather than matching constructors: `deadLetterReasonCode` returns the stable machine-facing code for **every** reason including the built-ins, `deadLetterReasonDetail` returns the optional human text, and `renderDeadLetterReason` produces the canonical `code: detail` form whose built-in strings are byte-for-byte unchanged. An adapter with structured storage should persist code and detail separately instead of parsing the rendered string.

Detail is transported verbatim. Keep it operationally bounded and free of secrets, raw payloads, raw SQL, and unrestricted backend error text — a dead-letter row is read by more people than a log line. Single-message processing spans expose only the code, as `shibuya.dead_letter.reason.code`, and use the canonical rendered reason as the error status description; detail is never an attribute or a metric label, so a high-cardinality detail cannot damage the metric series.

Exhaustive matches on `DeadLetterReason` must handle the new constructor or move to the projections. Review every adapter bound when crossing a core major version; the released 0.10 cohort requires adapters that admit its changed lifecycle types.

## Understand The Two Safety Substitutions

A handler exception caught by the runner becomes `AckRetry (RetryDelay 0)`, and the runner still finalizes it. This prevents loss, but an always-throwing handler can create an immediate redelivery storm. Decode and validate explicitly; catch expected failures and return a bounded retry, dead-letter, or halt decision.

If an adapter finalizer throws, Shibuya retries the same already-resolved decision after 10 ms, 50 ms, and 250 ms. It does not rerun the handler or recompute the decision. Exhaustion raises `ProcessorFailure` and retains a failed lifecycle outcome; it is an infrastructure failure, not an intentional `AckHalt`. Adapter finalizers must therefore be idempotent; application users get that behavior from the shipped adapters.

## Choose Ordering And Concurrency Together

`OrderingPolicy` is `StrictInOrder`, `PartitionedInOrder`, or `Unordered`. `Concurrency` is `Serial`, `Ahead n`, or `Async n`.

`validatePolicy` enforces `StrictInOrder` with `Serial` and rejects nonpositive or capacity-overflowing concurrency. Startup rejects duplicate processor IDs before acquisition. Partitioned queue processors share a global concurrency bound while serializing each partition; batching processors reject `PartitionedInOrder` with `Ahead` or `Async` because batch keys do not establish envelope partition order. `Ahead` yields results downstream in input order, but handlers and acknowledgments still execute concurrently; it does not order side effects. Some adapters impose stricter caller contracts: the Kafka adapter requires `Serial`, and Kiroku consumer-group members are serial.

Use `PartitionedInOrder` only when the adapter supplies a meaningful `Envelope.partition`. For batching processors, `PartitionedInOrder` with `Ahead` or `Async` is rejected because batches schedule by `BatchKey`, not envelope partition.

## Batch Only With Complete Decisions

```haskell
type BatchHandler es msg =
  BatchInfo -> NonEmpty (Message es msg) -> Eff es BatchAck
```

`BatchConfig` defaults to 100 messages or one second. `BatchAck` contains per-`MessageId` decisions plus a fallback, so every retained message always resolves deterministically. Prefer `ackAllOk`, `ackAll`, `ackExcept`, `withFallback`, or `failMessages` over manually constructing an incomplete map.

Message IDs must be unique inside a batch. Batch handlers remain subject to the same idempotent-finalizer and transport semantics as one-message handlers.

## Supervise And Drain Deliberately

`runApp` starts named processors with a bounded inbox per processor. `defaultAppConfig` uses `IgnoreFailures` and an inbox size of 100. Choose `StopAllOnFailure` when one unexpected processor failure invalidates the whole worker process; an intentional `AckHalt` is a graceful processor exit and does not stop siblings.

On shutdown, `stopAppGracefully` asks adapters to stop producing and drains in-flight work within `drainTimeout`; `totalShutdownTimeout` bounds adapter shutdown plus graceful draining before forced supervisor stop. Defaults are 30 and 60 seconds respectively. A forced stop returns `False`; repeated or concurrent stops share the shutdown result. Keep adapter resources alive until shutdown finishes. Neither deadline bounds arbitrary uninterruptible consumer code.

Use the published Shibuya 0.10.0.1 core/metrics pair with adapters that admit 0.10. Extend direct `ShutdownConfig` construction, exhaustive `ConfigError` / `PolicyError` matches, and `ProcessorState.Processing` matches for its last-progress field. Startup and shutdown own cleanup through cancellation; an idle intake wakes after halt or finalization failure. Retained terminal failures remain visible to health even after live metrics unregister. See [Shibuya inspection](shibuya-inspection.md).

## Bound batch-key cardinality separately

`inboxSize` bounds the processor inbox, not the number of distinct in-progress batch keys. Bound externally controlled key cardinality in the application; a per-batch size limit does not bound the batcher's total retained map. Do not turn a finite benchmark's bytes-per-key measurement into a production memory guarantee.

## Related Patterns

- [Transport selection](transport-selection.md)
- [PGMQ jobs](pgmq-jobs.md)
- [Kiroku subscriptions](kiroku-subscriptions.md)
- [Process managers](process-managers.md)
