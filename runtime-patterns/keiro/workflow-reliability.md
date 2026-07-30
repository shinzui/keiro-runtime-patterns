---
type: Standard
title: "Workflow reliability and recovery"
description: "Lease sizing, the failure budget, terminal-failure resurrection, and the durable wake-source lifecycle"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-workflow-reliability
tags: [keiro, workflow-reliability]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-23T16:55:16-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Workflow reliability and recovery

**Size the lease to one step, budget the retries, and recover a terminally failed workflow with the supported API instead of SQL.**

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

- **Awakeable ids are signalable as soon as they are observable.** The row is registered inside the journaled allocation step's action, before the id can be returned or handed to an external system, so an immediate external signal is no longer rejected as an unknown id.
- **Cancellation and completion are mutually exclusive.** `signalAwakeable` re-reads status inside its transaction; if a cancel won the race it appends nothing and returns `False`. Compensation and completion can no longer both fire.
- **A failed child is observable across rotation.** The child link persists its terminal failure reason, so `awaitChild` raises `WorkflowChildFailed` even after the parent rotates past the generation that held the original failure sentinel.
- **A sleep belongs to the generation that armed it.** A stale timer re-fire after `continueAsNew` becomes an idempotent append check on its original generation and can never resolve a same-named sleep on the next one. Re-arming a due sleep no longer postpones `wake_after`, and firing clears that hint atomically with the journal append, so a fired sleeper is rediscovered promptly.
- **GC collects sleep timers, not just terminal ones.** Workflow garbage collection removes every workflow-sleep timer owned by an eligible terminal instance in any status, and a claimed timer whose instance is `completed`, `cancelled`, or `failed` cancels itself. A timer can no longer resurrect a collected workflow from incomplete history.
- **Snapshots cannot hide a wake result.** On an `awaitStep` miss the runtime consults the generation-scoped `keiro.keiro_workflow_steps` index before arming or suspending, so a completion journaled concurrently with a snapshotting run is still delivered.

That last guarantee has a standing obligation for anyone extending the runtime: **every workflow journal append path must record its `keiro_workflow_steps` row in the same transaction.** The fallback's correctness depends on it.

## Operate the checklist

- Run `resumeWorkflowsOnce` on a polling loop and export every `ResumeSummary` field; `failed`, `leaseSkipped`, and `transientErrors` distinguish a code defect from worker contention from a database problem.
- Schedule `runWorkflowTimerWorker` whenever any workflow body sleeps.
- Configure `runWorkflowGcWorker` from a deliberate `WorkflowGcPolicy`. It is retention housekeeping, not a progress mechanism, but it is what keeps collected workflows from leaving armed timers behind.
- Repair a stuck awakeable with `cancelAwakeable`; repair a parent stuck on a never-finishing child by driving or cancelling the child.

For the authoring surface and full API, see the keiro repo's `docs/guides/durable-workflows.md` and ADRs 0005–0008.

## Related Patterns

- [Durable workflows](durable-workflows.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Telemetry](telemetry.md)
- [Keiro gotchas](gotchas.md)
