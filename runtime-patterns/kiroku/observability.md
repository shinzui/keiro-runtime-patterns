---
type: Guide
title: "Kiroku Observability"
description: "Wiring kiroku-metrics and kiroku-otel: collector composition, spans, Prometheus names, health probes"
timestamp: 2026-08-06T22:43:02Z
generated:
  by: human:nadeem
  at: "2026-08-06T22:43:02Z"
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

`existingEventHandler` above is the `Maybe` already on `baseSettings`. In a Keiro service it is rarely the only other claimant on that field — see [composing every `eventHandler` claimant](#compose-every-eventhandler-claimant) before treating this example as complete.

## Trace subscription lifecycle and event causality

Create a subscription lifecycle callback with:

```haskell
traceEvents <- subscriptionTraceHandler tracer
```

Its type is `Tracer -> IO (KirokuEvent -> IO ())`; compose the returned handler into `eventHandler` alongside metrics and logging. It opens short lifecycle and batch spans. Configure a batch span processor: callback execution is synchronous, and a blocking exporter would stall subscription work.

Set `StoreSettings.enrichEvent` to inject W3C context with `injectTraceContext currentSpanContext`. It writes `traceparent` and `tracestate` into event metadata while preserving other keys. The Shibuya Kiroku adapter consumes that metadata and adds Kiroku identity attributes to downstream processing spans.

## Compose every `eventHandler` claimant

`eventHandler` is one field, and in a Keiro service three packages want it. `metricsEventHandler` and `kirokuEventBridge` are wrappers that take the next handler as a delegate; `subscriptionTraceHandler` returns a leaf handler, so fan out to it explicitly. Assigning any one of them last, without threading the others through, silently drops the rest.

```haskell
-- kiroku-otel returns a leaf handler, not a wrapper: fan out to it explicitly.
let baseHandler ev = traceEvents ev >> appEventHandler ev

-- keiro counts the terminal dead-letter event; kiroku-metrics wraps the result.
let bridged = kirokuEventBridge keiroMetrics baseHandler

settings =
  baseSettings
    { eventHandler = Just (metricsEventHandler km (Just bridged))
    , observationHandler = Just (metricsObservationHandler km existingObservationHandler)
    }
```

`Keiro.Telemetry.kirokuEventBridge` is the claimant services forget, because Keiro's other instruments arrive by a different route. `keiro.outbox.deadlettered` and `keiro.dispatch.deadlettered` are recorded inside Keiro's own outbox and process-manager paths, so threading `KeiroMetrics` through option records is enough for them. `keiro.subscription.deadlettered` has no internal recorder at all: the bridge is its only source. A service that installs Kiroku's collector here and threads `KeiroMetrics` only into command and worker options exports that counter permanently at zero, and loses the signal that a subscription exhausted its retry ceiling.

That constrains startup order. Every handle these wrappers close over — `KirokuMetrics`, the `Tracer`, and `KeiroMetrics` — must exist before `ConnectionSettings` is built, and therefore before `withStore`. `newKeiroMetrics` is the easy one to defer, because its other use is threading into option records assembled later; build it with the rest of the telemetry instruments at startup. See [telemetry](../keiro/telemetry.md).

`observationHandler` is a separate slot with one claimant today; the Keiro bridge observes `KirokuEvent`, not `Observation`. Every wrapper in the chain invokes its delegate synchronously, so the whole chain must stay non-blocking.

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
- [Keiro telemetry](../keiro/telemetry.md)
