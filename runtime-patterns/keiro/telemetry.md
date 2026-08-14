---
type: Standard
title: "Telemetry"
description: "Keiro tracing, command-decision and position-distance metrics, W3C propagation, Kiroku bridging, and logging seams"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
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

The rule is one sentence: create telemetry instruments once at startup, before the store opens, and deliver them through both the runtime's option records and the Kiroku connection's `eventHandler`.

`Keiro.Telemetry` is keiro's sole dependency seam to `hs-opentelemetry-api`. Supply a `Tracer` to enable `withProducerSpan`, `withConsumerSpan`, `withCommandSpan`, and `withWorkflowSpan`; a missing tracer makes each helper a pass-through. These spans carry standard messaging/database attributes and bounded `keiro_*` runtime attributes.

Call `newKeiroMetrics meter` once to construct `KeiroMetrics`, whose instruments cover commands, snapshots, projection rebuilds and position distance, inbox/outbox, timers, dispatch, and workflows. Thread `Maybe KeiroMetrics` through `#metrics` on command, worker, and workflow options as shown in [runtime assembly](runtime-assembly.md).

The preferred projection gauge is `keiro.projection.global_position_distance`, recorded with `recordProjectionGlobalPositionDistance`. It subtracts the slowest durable member checkpoint from the newest **visible** store head, in `{position}` units. It is an opaque cursor distance, not event lag or backlog, and it returns zero when no visible work remains. `keiro.projection.lag` and `recordProjectionLag` remain only as deprecated compatibility aliases carrying the same value; do not use their historical name in new dashboards. See [Kiroku durable checkpoint inventory](../kiroku/checkpoint-inventory.md).

Command decisions have their own bounded surface. The `keiro.command.decision` span attribute and the `keiro.command.decisions` counter take exactly `accepted`, `rejected`, or `no_op`; application rejection and no-op payloads must never reach a label or an error description. See [command cycle and errors](command-cycle-and-errors.md).

Projection rebuilds export starts, resumes, committed pages and events, failures, promotions, and page duration under `keiro.projection.rebuild.*`. Alert on failures and on a promotion that never arrives, not on page counts.

Option records carry most of those instruments, but not all of them. `keiro.subscription.deadlettered` has no internal recorder anywhere in Keiro: its only source is `kirokuEventBridge metrics delegate`, composed into the Kiroku connection's `eventHandler`. It increments the counter only for `KirokuEventSubscriptionDeadLettered`, then invokes the delegate synchronously; keep that delegate fast. Query the durable dead-letter table for current depth rather than treating the counter as a gauge.

Contrast that with its siblings: `keiro.outbox.deadlettered` and `keiro.dispatch.deadlettered` are recorded inside Keiro's own outbox and process-manager paths, so for those two the option threading above is sufficient. A service that threads `KeiroMetrics` only into command, worker, and workflow options therefore exports subscription retry exhaustion permanently at zero — the failure is invisible precisely where it looks covered.

Because the bridge is installed on `ConnectionSettings`, `newKeiroMetrics` must run before the store opens, earlier than the option records it also feeds. Build it with the service's other telemetry instruments at startup, and expect to share `eventHandler` with `kiroku-metrics` and `kiroku-otel`; [Kiroku observability](../kiroku/observability.md) shows the composed chain.

## Propagate the remote parent

The rule is one sentence: inject `traceparent` and `tracestate` before persistence and restore them when consuming.

Use `traceContextFromCurrentSpan`, `injectTraceContext`, and `traceContextFromHeaders` rather than parsing headers ad hoc. Keiro persists W3C context in outbox and inbox columns so producer and consumer spans can remain one trace across asynchronous publication and delivery.

## Wire the application logger

Keiro intentionally ships no structured-logging framework and no request logger. Production services must connect both available runtime seams to their chosen logger:

- Set subscription shard `onShardError` to record `ShardWorkerError`; the default is no hook. It is the signal behind a shard intervention: inspect ownership with `shard status`, and use `shard relinquish` only for a worker known dead, because releasing a live worker's buckets produces concurrent processing. See the [operations console](operations-console.md).
- Set workflow resume `logEvent` to record `ResumeLogEvent`; its default is a compact stderr renderer.

Metrics and traces do not replace these diagnostic events, and the hooks must remain non-blocking enough for their workers.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [Durable workflows](durable-workflows.md)
- [Kiroku observability](../kiroku/observability.md)
- [Kiroku durable checkpoint inventory](../kiroku/checkpoint-inventory.md)
