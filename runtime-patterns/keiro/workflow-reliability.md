---
type: Standard
title: "Workflow reliability and recovery"
description: "Exact wake discovery, bounded concurrent resume, terminal arbitration, failure recovery, and durable wake-source obligations"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-workflow-reliability
tags: [keiro, workflow-reliability]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-23T23:55:16Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Workflow reliability and recovery

**Let the instance row govern exact discovery, arbitrate terminal state inside journal appends, and recover through supported lifecycle APIs instead of SQL.**

This standard covers what a service owner must configure and operate so a durable workflow makes progress under crashes, worker takeover, concurrent wake sources, and repeated application failure. [Durable workflows](durable-workflows.md) covers the journal and the workers themselves.

## Size the lease to a single boundary

The rule is one sentence: set `WorkflowResumeOptions.leaseTtl` above the slowest *individual* step action or await arm, not above the whole multi-step advance.

The resume worker claims each instance for `leaseTtl` and passes those coordinates into the run as a `WorkflowRunOptions.leaseHeartbeat`. The runtime renews for another full TTL before every fresh step action and every unresolved await arm; replay hits neither write nor renew. A healthy long workflow therefore no longer loses ownership merely because its original claim aged out.

- The default `leaseTtl` is 60 seconds and the default `maxAttempts` is 5.
- Include a step's own timeout when sizing. An action that can block for 90 seconds needs a TTL above 90 seconds.
- Expiry still governs dead-worker takeover, so do not inflate it far beyond the slowest boundary.
- Leave `leaseHeartbeat` at `Nothing` for direct `runWorkflow` calls. Only the resume worker populates it.

When another worker owns the row at a boundary, the runtime throws `WorkflowLeaseLost` *before* running further side effects. The resume worker counts that as `leaseSkipped` and consumes no crash attempt.

## Budget the failure path explicitly

A synchronous exception escaping a workflow body consumes one attempt. Retries are scheduled with exponential delays of 2, 4, 8, 16, 32, then 64 seconds (capped there). Store errors are classified separately as transient, are reported as `transientErrors`, and consume no attempt.

Choose `maxAttempts` for the longest application outage the worker should ride through, counting both the backoff sum and each attempt's own runtime. At the default of 5 attempts, roughly 30 seconds of scheduled backoff precede the terminal failure.

Once the ceiling is reached, the runtime appends `WorkflowFailed`, sets instance status to `failed`, and drops the instance from ordinary resume discovery. `runWorkflow` returns the `Failed` outcome. **Nothing retries it again**; a terminally failed workflow is invisible to the worker until an operator acts. Alert on the `failed` counter in `ResumeSummary` rather than discovering these by hand.

Failure and cancellation are enforced at the next fresh workflow boundary. The journal-append transaction refuses an ordinary `StepRecorded` after `__workflow_failed__` or `__workflow_cancelled__` with `JournalRefusedTerminal`; a direct run racing the resume worker cannot continue fresh side effects after the terminal marker wins. Wake sources settle their own durable rows on that outcome and deliver nothing.

## Recover terminal failure through `resurrectFailedWorkflow`

The rule is absolute: never repair a failed workflow with manual SQL against the instance and step-index tables.

```haskell
outcome <-
  resurrectFailedWorkflow
    (WorkflowName "order-fulfillment")
    (WorkflowId "order-123")

case outcome of
  WorkflowResurrected -> pure ()
  WorkflowNotFailed   -> alreadyRunnable
  WorkflowNotFound    -> unknownInstance
```

`Keiro.Workflow.Instance.resurrectFailedWorkflow` acts only when instance status is `failed`. In one transaction it resets status, attempts, error, retry time, lease, and completion metadata; deletes the current generation's derived `__workflow_failed__` step-index row; and revives a failed child link when the instance is a child.

Failure history is immutable. The historical `WorkflowFailed` event is never deleted, so the audit trail survives and every completed step still replays instead of repeating its side effects. Repair the underlying defect *before* resurrecting, or the workflow simply consumes a fresh budget and fails again — which appends a second, distinctly identified failure event on the same generation.

Parent and child recover independently. A failure sentinel already delivered into a parent's journal is immutable; resurrect the parent separately when its own terminal state should be retried. The runtime records failures, not administrative commands, so capture operator and ticket identity in your own audit trail.

## Rely on the wake-source lifecycle guarantees

These are runtime invariants, not things a service configures. Know them because they define what an operator may assume when a workflow looks stuck.

- **Discovery is exact.** `findUnfinishedWorkflowIds` returns only `running` instances and `suspended` instances whose `wake_after` is due. A workflow parked on an awakeable, child, or future sleep is quiescent until its wake source updates the instance row.
- **Awakeable ids are opaque and signalable as soon as they are observable.** Allocation generates a random id and commits its `pending` row inside the journaled allocation step, before the id can be returned or handed to an external system, so an immediate external signal is not rejected as unknown. Nothing outside the workflow can derive the id of a fresh allocation; it must be published. See [durable workflows](durable-workflows.md).
- **Cancellation and completion are mutually exclusive.** `signalAwakeable` re-reads status inside its transaction; if a cancel won the race it appends nothing and returns `False`. Compensation and completion can no longer both fire.
- **A failed child is observable across rotation.** The child link persists its terminal failure reason, so `awaitChild` raises `WorkflowChildFailed` even after the parent rotates past the generation that held the original failure sentinel.
- **A sleep belongs to the generation that armed it.** A stale timer re-fire after `continueAsNew` becomes an idempotent append check on its original generation and can never resolve a same-named sleep on the next one. Re-arming a due sleep no longer postpones `wake_after`, and firing clears that hint atomically with the journal append, so a fired sleeper is rediscovered promptly.
- **GC collects sleep timers, not just terminal ones.** Workflow garbage collection removes every workflow-sleep timer owned by an eligible terminal instance in any status, and a claimed timer whose instance is `completed`, `cancelled`, or `failed` cancels itself. A timer can no longer resurrect a collected workflow from incomplete history.
- **Snapshots cannot hide a wake result.** On an `awaitStep` miss the runtime consults the generation-scoped `keiro.keiro_workflow_steps` index before arming or suspending, so a completion journaled concurrently with a snapshotting run is still delivered.
- **Suspension and delivery arbitrate on the awaited step.** `markInstanceSuspendedAwaiting` writes the generation and awaited step under the shared per-step lock, so a concurrent delivery cannot leave a journaled wake behind a stale suspended instance row.

These guarantees impose a standing obligation for anyone extending the runtime: **every workflow journal append path must record its `keiro_workflow_steps` row and the corresponding instance lifecycle transition in the same transaction.** The fallback and exact discovery both depend on it.

## Implement custom wake sources as durable ledgers

A third-party wake source owes four things:

1. Store a durable row keyed by the logical workflow, not one generation.
2. Deliver by appending the result under the exact awaited step name.
3. Re-check and re-deliver from the await arm, repairing a delivery stranded by `continueAsNew` rotation.
4. Update the owning instance row in every lifecycle transition transaction. `appendJournalEntryReturningId` does this for a delivered result; an abandonment path that appends nothing must do it itself.

If the append returns `JournalRefusedTerminal`, settle the wake-source row and deliver nothing. Do not interpret a quiet append wrapper as proof that the workflow received the value. Also remember that `continueAsNew` abandons awakeable ids already handed out; the next generation allocates a fresh opaque id and must republish it to its holder through an idempotent, id-keyed callback.

## Freeze deterministic identity

Workflow journal, sleep-timer, awakeable, and process-manager ids now hash the UTF-8 bytes of their text seed. ASCII-derived ids remain byte-identical; non-ASCII seeds derive different ids and can produce bounded at-least-once duplicates across the deployment boundary. There is no migration. Treat `identitySeedBytes` and every seed composition as frozen replay identity: any future change requires a versioned adoption path.

## Operate the checklist

- Use `resumeWorkflowsOnceUpTo` for bounded operator passes. For service workers, start with `maxConcurrentAdvances = 1`; raise it only against measured connection-pool headroom, and make `logEvent` thread-safe because concurrent advances call it from several threads. Export every `ResumeSummary` field; `failed`, `leaseSkipped`, and `transientErrors` distinguish a code defect from worker contention from a database problem.
- Terminate a bounded drain on durable progress, not on the discoverable pool. `advanced` is the continuation signal; `paced`, `sleepDue`, `unregisteredNames`, foreign leases, and transient errors each name a blocked remedy and must stop the loop rather than let it spin. A workflow suspended on a due sleep while no timer worker runs reports `advanced = 0` and `sleepDue = 1` — the fix is to run the timer worker, not another resume pass.
- Schedule workflow timer polling whenever any body sleeps, and drain backlogs with `drainWorkflowSleepTimers`/`drainDueTimersWith` rather than one timer per poll tick.
- Configure `runWorkflowGcWorker` from a deliberate `WorkflowGcPolicy`. It is retention housekeeping, not a progress mechanism, but it is what keeps collected workflows from leaving armed timers behind.
- Treat a skipped crash record as an ordinary terminal race and keep the pass running. Run GC with per-instance isolation and a logging hook so one bad deletion or pass does not kill the worker.
- Repair a stuck awakeable with `cancelAwakeable`; repair a parent stuck on a never-finishing child by driving or cancelling the child.

For the authoring surface and full API, see the keiro repo's `docs/guides/durable-workflows.md` and ADRs 0005–0008.

## Related Patterns

- [Durable workflows](durable-workflows.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Telemetry](telemetry.md)
- [Keiro gotchas](gotchas.md)
- [Keiro operations console](operations-console.md)
