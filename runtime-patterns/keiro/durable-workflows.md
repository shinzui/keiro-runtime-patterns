---
type: Guide
title: "Durable workflows"
description: "Durable workflow journals, at-least-once step effects, opaque awakeable publication, bounded progress workers, custom wakes, and evolution"
timestamp: 2026-09-01T16:07:10Z
generated:
  by: human:nadeem
  at: "2026-09-01T16:07:10Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-durable-workflows
tags: [keiro, durable-workflows]
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

# Durable workflows

**Workflow journals resume deterministically; deploy each progress mechanism the workflow actually uses.**

This guide orients service owners to keiro's durable workflow runtime while leaving authoring details to the upstream workflow guides.

## Run and replay the journal

The rule is one sentence: invoke `runWorkflowWith options name workflowId body` and put every side effect behind a recorded workflow operation. `WorkflowId` and `AwakeableId` are runtime-owned nominal types: use them directly and never flatten them to `Text` in the domain. Service-owned identifiers carried by a workflow follow [domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md).

The runner drives the body until completion or suspension. Its ordinary event stream is named `wf:<name>-<id>` and decoded with `workflowJournalCodec`; generations opened by `continueAsNew` receive a generation suffix. A named `step` runs its action and then journals the result; once that record is durable, replay returns it without re-running the action.

**Step effects are at-least-once, not exactly-once.** A crash after the external effect succeeds but before the journal append commits runs the action again on the next attempt. Every step action that touches an external system must be idempotent — an upsert, a keyed callback, a request carrying its own deduplication token. Treating a journaled step as exactly-once is the most expensive way to learn this rule.

`WorkflowOutcome` is `Completed a | Suspended | Cancelled | Failed | ContinuedAsNew`. `Failed` is terminal: the instance has exhausted its attempt budget and left resume discovery. Handle it deliberately — see [workflow reliability and recovery](workflow-reliability.md).

Workflow bodies must be deterministic outside recorded operations. Prefer stable explicit names such as `sleepNamed`; ordinal `sleep` labels can drift when control flow changes.

Snapshots are safe to combine with awakeables, children, and sleeps. An `awaitStep` miss consults the generation-scoped workflow step index before arming and suspending, so a completion journaled concurrently with a snapshotting run cannot be hidden by that snapshot.

## Publish the allocated awakeable id; never recompute one

`awakeableNamed` allocates an **opaque** random `AwakeableId`, journals it under the reserved `awkid:<label>` step prefix, and returns it with its `await` action. The resolved payload is later journaled under `awk:<uuid>`. Replay reads the journaled id, so a resumed workflow hands out the id it already handed out — without that id ever being derivable from public workflow coordinates.

The consequence is a contract, not a style note:

- Hand the returned id to the external system through an application-owned publication action **before** awaiting it. There is no function that computes the id of a fresh allocation.
- That publication action is an ordinary step and therefore at-least-once. Make it upsert or deduplicate on the id itself.
- Generated code follows the same shape: a `WorkflowRuntime` module exposes an abstract `AwaitBinding` per declared await plus `allocateDeclaredAwait`, which allocates through the runtime and returns the opaque id with its await action. The pure `awaitAwakeableId` coordinate helper is gone, and consumers of generated runtimes now need the direct dependencies that effectful allocation requires.
- `Keiro.Workflow.Awakeable.Compatibility` reproduces generation-0 identifiers (`generation0AwakeableId`, `preUtf8Generation0AwakeableId`) for inspecting and adopting awakeables written before this contract. It predicts nothing about a fresh allocation; do not import it into ordinary workflow code.

The public signatures also carry the effects the allocation really needs: `awakeableNamed` and `awaitChild` require `IOE`, and `runWorkflow`, `runWorkflowWith`, and the resume entry points require `Error StoreError`.

## Deploy progress mechanisms by capability

The rule is one sentence: always run resumption for suspended workflows, schedule timer polling when using sleep, and deliver external awakeable signals where the integration occurs.

- `resumeWorkflowsOnceUpTo` is the bounded test and operations pass; `resumeWorkflowsOnce` retains the unbounded compatibility behavior. Use `runWorkflowResumeWorker`, `runWorkflowResumeWorkerWith`, or `runWorkflowResumeWorkerPush` for continuous service operation. Discovery is exact: only `running` instances and `suspended` instances with a due wake hint are returned, so parked awakeables, children, and future sleeps cost no resume passes. Its `ResumeSummary` reports `discovered`, `advanced`, `resumed`, `completed`, `stillSuspended`, `unknownName`, `failed`, `transientErrors`, `leaseSkipped`, `paced`, `sleepDue`, and the deduplicated `unregisteredNames` set; export all of them. Continue a bounded drain on `advanced`, never on `discovered`.
- The resume default is `maxConcurrentAdvances = 1`. Raise it only against store connection-pool headroom and make `logEvent` thread-safe when several candidates advance at once.
- `runWorkflowTimerWorker` is the compatibility one-row firing pass. Schedule timer polling when workflow bodies use `sleep` or `sleepNamed`, and use `drainWorkflowSleepTimers` or `drainDueTimersWith` for bounded backlog drains.
- `signalAwakeable` completes external waits idempotently and journals the result in the same transaction, for the exact allocated id. It returns `False` without appending when cancellation won the race.
- `runWorkflowGcWorker` is optional retention housekeeping for terminal instances. Configure it from a deliberate `WorkflowGcPolicy`; it is not required for workflow progress, but it is what removes the sleep timers a collected workflow would otherwise leave armed.

Nest defaults through lenses:

```haskell
resumeOptions metrics =
  defaultWorkflowResumeOptions
    & #runOptions .~
        (defaultWorkflowRunOptions & #metrics .~ metrics)
```

## Evolve live definitions deliberately

Stable recorded names are compatibility contracts. Use `patch` for a cross-cutting branch that in-flight instances must remember, and `continueAsNew` to rotate long-lived state into a fresh generation. `continueAsNew` records the active patch set atomically with the seed, so an asynchronous wake append before the generation's first run cannot force every patch decision to the old branch.

Rotation invalidates any awakeable id already handed to an external holder. The next generation allocates a **fresh opaque id**, and the id the prior generation published no longer wakes the live instance. Publish the new id again through the same idempotent, id-keyed callback as part of the new generation's allocation.

A journaled step result is permanent. Never change the type a step decodes into: rename the step so it runs fresh, or guard the change with a stable `patch`. Put specification changes through the [keiro-dsl evolution gate](dsl-adoption.md) and the [rollout ordering rules](evolution-and-rollout.md) before deployment.

## Honor the custom wake-source contract

A custom wake source needs a durable logical-workflow row, delivery under the awaited step name, an await arm that re-checks and re-delivers after a rotation race, and an instance-row write on every resolution or abandonment transition. A terminal journal refusal settles the source row but delivers nothing. The complete recovery and arbitration rules live in [workflow reliability and recovery](workflow-reliability.md).

Deterministic workflow identities now hash UTF-8 seed bytes. ASCII ids are unchanged; non-ASCII seeds move without a migration and can cross the upgrade boundary with bounded at-least-once duplication. Never change the derivation or seed composition as an ordinary refactor.

For authoring, awaitables, children, and sleep semantics, see the keiro repo's `docs/user/durable-workflows.md` and `docs/guides/durable-workflows.md`.

## Related Patterns

- [Workflow reliability and recovery](workflow-reliability.md)
- [Domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md)
- [Runtime assembly](runtime-assembly.md)
- [Telemetry](telemetry.md)
- [Keiro-dsl adoption](dsl-adoption.md)
- [Keiro operations console](operations-console.md)
