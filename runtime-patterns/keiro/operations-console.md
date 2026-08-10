---
type: Runbook
title: "Keiro operations console"
description: "Mounting and operating keiro-ops with schema checks, preview-before-force mutations, application hooks, and stable JSON"
timestamp: 2026-08-10T13:59:20Z
generated:
  by: human:nadeem
  at: "2026-08-10T13:59:20Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-operations-console
tags: [keiro, operations-console]
status: current
---

# Keiro operations console

**Operate Keiro through `keiro-ops` and mounted supported APIs; never build an administrative side door into framework-owned tables.**

`keiro-ops` is post-0.11 source and is not a released standalone package in the 0.11.0.0 cohort. Keep its operational contract tied to the coherent Keiro revision that supplies the runtime APIs it wraps.

## Fail closed before mutation

Every invocation must verify the live Keiro schema against the binary. Read-only commands may continue while rendering drift warnings. A mutation must refuse drift unless the operator explicitly supplies `--allow-schema-drift` after reviewing the mismatch.

Mutating commands must return an exact preview and a quoted `--force` reinvocation before changing state. Permanent stream operations additionally require the stream name to be typed in human mode. Preserve deliberate preview exit codes; do not translate them into an operational exception.

Use the human table for interactive work and `--json` for automation. Both render the same typed result value. Treat the versioned JSON shape as the automation contract; do not scrape tables or stderr.

## Keep database-owned and application-owned commands separate

The standalone executable may expose only operations whose complete contract lives in the database and a public library API: workflow inspection and generic lifecycle repair, timer and queue inspection, inbox/outbox state, snapshots, shards, streams, and durable checkpoint inventory.

Mount code-dependent commands in the application binary with `AppHooks` and `mainWithHooks`, or compose `opsCommandTree` and `runOpsInvocation` into the application's parser. Supply only the hooks the application can execute:

- `workflowResume` for a bounded pass over the application `WorkflowRegistry`;
- `timerFire` for the application's timer dispatch action;
- `replayAudit` for candidate codecs and audit targets;
- `projectionCatalog` for operations derived from the mounted validated catalog.

A hook-dependent command must be absent from help when the hook is absent. Do not expose a placeholder command that can be invoked without its application authority.

## Wrap supported lifecycle APIs

Use `cancelWorkflow`, `resurrectFailedWorkflow`, `forceReleaseInstanceLease`, `cancelAwakeable`, and `signalAwakeable` for workflow repair. Cancellation is append-only and takes effect at a durable boundary; it does not recursively cancel descendants. Inspect the typed outcome before declaring success.

Use bounded passes for interactive operations: `resumeWorkflowsOnceUpTo`, `drainDueTimersWith`, and bounded garbage collection. An operations process must not accidentally become an unbounded service worker.

Read subscriptions through Kiroku's public checkpoint inventory, not its table layout. Derive projection position through the public helper and label it `global_position_distance`, never event lag.

Mount `ProjectionCatalogOperations` for catalog inventory and rebuild preview/start/status/resume/abandon. Do not maintain another name-to-target or name-to-handler map in the console. A failed or abandoned rebuild stays fenced.

## Preserve operator evidence

Capture the preview, JSON result, operator identity, ticket or incident, binary revision, and database target for every forced mutation. `keiro-ops` records runtime failure evidence where the underlying API supports it, but it does not own the organization's administrative audit log.

## Related Patterns

- [Projection catalogs](projection-catalogs.md)
- [Workflow reliability and recovery](workflow-reliability.md)
- [Kiroku durable checkpoint inventory](../kiroku/checkpoint-inventory.md)
- [Migration operations](../migrations/operations.md)
- [Runtime assembly](runtime-assembly.md)
