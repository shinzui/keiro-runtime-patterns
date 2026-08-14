---
type: Runbook
title: "Keiro operations console"
description: "Mounting and operating keiro-ops with schema checks, preview-before-force mutations, application hooks, and stable JSON"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-operations-console
tags: [keiro, operations-console]
status: current
---

# Keiro operations console

**Operate Keiro through `keiro-ops` and mounted supported APIs; never build an administrative side door into framework-owned tables.**

`keiro-ops` is published as part of the Keiro 0.12.0.0 package set and moves with it. Run the console binary built from the same set as the runtime it operates; a console from another cohort is drift, not convenience.

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

Read subscriptions through Kiroku's public checkpoint inventory, not its table layout. `stream subscriptions` and `projection position --subscription NAME` preserve durable consumer-group member rows and report both the authoritative `store_position` and the reachable `visible_store_head`; the derived `global_position_distance` is computed from the visible head and is never an event count.

`wf resume-once` reports `advanced`, `paced`, `sleep_due`, and the sorted `unregistered_names` alongside the older counters, so an operator can terminate a bounded drain on durable progress and name the blocked remedy instead of re-running the pass.

Mount `ProjectionCatalogOperations` for the whole read-side surface, and do not maintain another name-to-target or name-to-handler map in the console:

- `rebuild list`, `rebuild preview`, `rebuild status`, `rebuild abandon`, and `rebuild adopt` for the offline lifecycle and slice adoption. Adoption reports through the `keiro/catalog-adoption-preview/v2` and `keiro/catalog-adoption-outcome/v2` envelopes, distinguishes the named groups it will adopt from out-of-scope catalog drift, warns about skipped groups that will still refuse startup registration, and refuses a group absent from the catalog with `AdoptGroupNotInCatalog` in both preview and forced execution.
- `rebuild versioned start|status|resume|abandon`, read-only `rebuild retired`, and preview/`--force` `rebuild drop-retired` for schema-versioned generations. The physical fleet is derived from the mounted validated catalog; the console never accepts a caller-supplied fleet list.
- `rebuild reproject-stream GROUP PROJECTION STREAM` for [targeted stream repair](stream-scoped-repair.md), whose positive `--max-events` defaults to 1000 and is rechecked against locked stream metadata before the group fence.
- Read-only `rebuild external-read CONTRACT VERSION` and preview/`--force` `rebuild retire-external-read CONTRACT VERSION` for the guarded external-read surface, rendering contract state, surface generation, PostgreSQL dependents, and execute grants.

A failed or abandoned rebuild stays fenced. `rebuild status` and the non-forced `rebuild abandon` preview also work for pre-canonical runs, which is what makes the documented abandon, adopt, and fresh-start recovery sequence possible without direct SQL.

## Preserve operator evidence

Capture the preview, JSON result, operator identity, ticket or incident, binary revision, and database target for every forced mutation. `keiro-ops` records runtime failure evidence where the underlying API supports it, but it does not own the organization's administrative audit log.

## Related Patterns

- [Projection catalogs](projection-catalogs.md)
- [Targeted stream-scoped projection repair](stream-scoped-repair.md)
- [Workflow reliability and recovery](workflow-reliability.md)
- [Kiroku durable checkpoint inventory](../kiroku/checkpoint-inventory.md)
- [Migration operations](../migrations/operations.md)
- [Runtime assembly](runtime-assembly.md)
