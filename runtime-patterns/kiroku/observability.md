---
type: Guide
title: "Kiroku Observability"
description: "Wiring kiroku-metrics and kiroku-otel: collector composition, spans, Prometheus names, health probes"
timestamp: 2026-07-22T16:52:58Z
generated:
  by: human:nadeem
  at: "2026-07-22T16:52:58Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-observability
tags: [kiroku, observability]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T16:52:58Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved kiroku-project checkout (kiroku-store, adapters, otel, metrics) and the keiro consumer's Connection API; verified exported symbols, signatures, version claims, and links.
---

# Kiroku Observability

**Compose metrics, traces, and passthrough callbacks before `withStore`, then probe both process health and subscription progress.**

Use this guide to wire `kiroku-metrics` and `kiroku-otel` into a service. It covers callback composition, trace propagation, endpoints, stable metric names, and Kubernetes health policy.

## Compose the collector before store acquisition

Construct `KirokuMetrics`, preserve any existing callbacks as passthroughs, and install both wrappers in `ConnectionSettings` before `withStore`. The collector update happens first and is an in-memory STM operation.

```haskell
settings =
  baseSettings
    { eventHandler = Just (metricsEventHandler km existingEventHandler)
    , observationHandler = Just (metricsObservationHandler km existingObservationHandler)
    }
```

`newKirokuMetrics` normally receives the live store because it reads publisher gauges. When startup order requires it, use the explicit STM-reader seam and finish wiring before traffic begins. Do not perform exporter I/O in either synchronous callback.

## Trace subscription lifecycle and event causality

Create a subscription lifecycle callback with:

```haskell
traceEvents <- subscriptionTraceHandler tracer
```

Its type is `Tracer -> IO (KirokuEvent -> IO ())`; compose the returned handler into `eventHandler` alongside metrics and logging. It opens short lifecycle and batch spans. Configure a batch span processor: callback execution is synchronous, and a blocking exporter would stall subscription work.

Set `StoreSettings.enrichEvent` to inject W3C context with `injectTraceContext currentSpanContext`. It writes `traceparent` and `tracestate` into event metadata while preserving other keys. The Shibuya Kiroku adapter consumes that metadata and adds Kiroku identity attributes to downstream processing spans.

## Serve the operational surface

`kiroku-metrics` defaults to port 9091. Its HTTP and WebSocket surface includes:

- `/metrics` and `/metrics/<name>` for JSON;
- `/metrics/prometheus` for Prometheus text;
- `/subscriptions` when a status provider is configured;
- `/health`, `/health/live`, and `/health/ready`;
- `/ws` for the WebSocket upgrade when store-aware serving is enabled.

Stable Prometheus names include `kiroku_events_appended_total`, `kiroku_active_subscribers`, `kiroku_pool_connections`, `kiroku_subscription_position`, `kiroku_subscription_lag`, `kiroku_subscriptions_stopped_total`, and `kiroku_hard_deletes_total`. Alert and dashboard against those names, not JSON field layout or rendered descriptions.

## Wire Kubernetes probes deliberately

Point liveness at `/health/live` and readiness at `/health/ready`. Add `postgresPing store` as a dependency check. Readiness fails when a subscription last stopped from overflow, when any observed lag exceeds `readinessMaxLag` (default 10,000), or when a dependency check fails.

Subscription lag is an upper bound: the collector learns a worker’s position at lifecycle and delivery callbacks, so a quiet caught-up worker can briefly look behind until the next callback. Choose alert windows and readiness thresholds with that sampling behavior in mind.

## Related Patterns

- [Connection Settings](./connection-settings.md)
- [Subscriptions](./subscriptions.md)
- [Operational Invariants](./operational-invariants.md)
