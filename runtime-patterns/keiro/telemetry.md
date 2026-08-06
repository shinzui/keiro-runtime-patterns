---
type: Standard
title: "Telemetry"
description: "Keiro tracing, metrics, W3C propagation, Kiroku bridging, and logging seams"
timestamp: 2026-07-22T17:49:54Z
generated:
  by: human:nadeem
  at: "2026-07-22T17:49:54Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-telemetry
tags: [keiro, telemetry]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T17:49:54Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Telemetry

**Use `Keiro.Telemetry` as the OTel seam, preserve W3C context across tables, and bring the service's logger.**

This standard covers keiro's opt-in traces, metrics, propagation, and the logging hooks applications must own.

## Supply telemetry through options

The rule is one sentence: create telemetry instruments once at startup and pass them through the runtime's option records.

`Keiro.Telemetry` is keiro's sole dependency seam to `hs-opentelemetry-api`. Supply a `Tracer` to enable `withProducerSpan`, `withConsumerSpan`, `withCommandSpan`, and `withWorkflowSpan`; a missing tracer makes each helper a pass-through. These spans carry standard messaging/database attributes and bounded `keiro_*` runtime attributes.

Call `newKeiroMetrics meter` once to construct `KeiroMetrics`, whose 40 instruments cover commands, snapshots, projection lag, inbox/outbox, timers, dispatch, and workflows. Thread `Maybe KeiroMetrics` through `#metrics` on command, worker, and workflow options as shown in [runtime assembly](runtime-assembly.md).

Compose `kirokuEventBridge metrics delegate` into the Kiroku connection's `eventHandler`. It increments Keiro's subscription-dead-letter counter only for `KirokuEventSubscriptionDeadLettered`, then invokes the delegate synchronously; keep that delegate fast. Query the durable dead-letter table for current depth rather than treating the counter as a gauge.

## Propagate the remote parent

The rule is one sentence: inject `traceparent` and `tracestate` before persistence and restore them when consuming.

Use `traceContextFromCurrentSpan`, `injectTraceContext`, and `traceContextFromHeaders` rather than parsing headers ad hoc. Keiro persists W3C context in outbox and inbox columns so producer and consumer spans can remain one trace across asynchronous publication and delivery.

## Wire the application logger

Keiro intentionally ships no structured-logging framework and no request logger. Production services must connect both available runtime seams to their chosen logger:

- Set subscription shard `onShardError` to record `ShardWorkerError`; the default is no hook.
- Set workflow resume `logEvent` to record `ResumeLogEvent`; its default is a compact stderr renderer.

Metrics and traces do not replace these diagnostic events, and the hooks must remain non-blocking enough for their workers.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [Durable workflows](durable-workflows.md)
