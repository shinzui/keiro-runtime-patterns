---
type: Standard
title: "Shibuya health and inspection"
description: "Serve released Shibuya lifecycle health and bounded WebSocket selections without assuming unpublished browser controls"
timestamp: 2026-10-14T21:56:57Z
generated:
  by: process:codex
  at: "2026-10-14T21:56:57Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-shibuya-inspection
tags: [messaging, shibuya, inspection]
status: current
---

# Shibuya health and inspection

**Use retained lifecycle state for readiness, bound inspector resources, and keep inspection tied to the deployed release.**

This standard covers the published `shibuya-core` / `shibuya-metrics` 0.10.0.1 pair. Mount `combinedApp` in an application-owned WAI server or use the bracketed metrics server. Inspection describes that process, not an entire deployment.

## Set the listener and dependency budgets explicitly

Start from `defaultConfig`. The listener defaults to `127.0.0.1:9090`; expose it beyond loopback only through the deployment's operational access boundary. `wsMaxConnections` defaults to 100, `wsMaxSubscriptions` to 1000, and push sampling to 100 ms. Bound retained selections and subscribe-all exclusions; exceeding the per-connection selection policy closes with 1008. Honour `enableWebSocket` for upgrades.

Supply `host`, `wsMaxSubscriptions`, and `dependencyTimeoutMicros` when migrating complete configuration records. Each dependency readiness check defaults to a one-second deadline. A hung check or synchronous exception becomes unhealthy; asynchronous cancellation remains cancellation.

## Separate liveness, readiness and progress

Probe `/health/live` for the master lifecycle and `/health/ready` for application readiness. A stopped master is not live. Readiness includes explicit application status, dependencies, configured processors and retained terminal failures. `IgnoreFailures` does not erase a failure when its live metrics entry disappears. An intentionally stopped processor is not interchangeable with a healthy running worker.

Stuck detection uses sampled last progress, not the start of a continuous processing burst. `ProcessorState.Processing` has the progress field and the wire carries `lastProgress`; update exhaustive matches. Keep a workload-appropriate `stuckThreshold` (default 60 seconds). Do not treat a missing live metrics row as proof of success.

## Maintain a client snapshot and terminal state

At `/ws`, use `subscribe_all`, `subscribe`, `unsubscribe`, and `ping`. Apply `snapshot` as a replacement of the selected live metrics, then apply processor `update` frames. Handle `terminal` separately: a formerly visible processor has left the live registry with retained `stopped` or `failed` status. Preserve failure detail rather than silently dropping the row. Handle `goodbye` as server shutdown and reconnect with a fresh subscription snapshot.

Extend exhaustive `ServerMessage` matches for `ProcessorTerminal`, and direct WebSocket state construction for shutdown state. Ignore additive fields and keep process identity on every displayed panel.

## Keep unreleased browser features outside the baseline

The reviewed source after 0.10.0.1 adds explicit CORS/Origin policy, stable error codes, bounded outbound frames/bytes and send deadlines, detailed latency and acknowledged cursor progress, intake pause/resume, and processor-lifetime tracing. These APIs are not in the published pair. Do not configure their record fields or claim their delivery guarantees on 0.10.0.1. Reconcile this standard when that cohort is published; existing selection bounds do not establish outbound queue or send-time bounds.

## Related Patterns

- [Shibuya processing](shibuya-processing.md)
- [Messaging gotchas](gotchas.md)
- [Kiroku inspection](../kiroku/inspection.md)
- [Kubernetes deployment](../config/kubernetes-deployment.md)
