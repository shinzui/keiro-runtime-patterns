---
type: Guide
title: "Durable workflows"
description: "Durable workflow journals, exact discovery, bounded progress workers, stable steps, custom wakes, and evolution"
timestamp: 2026-08-10T13:59:20Z
generated:
  by: human:nadeem
  at: "2026-08-10T13:59:20Z"
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

The rule is one sentence: invoke `runWorkflowWith options name workflowId body` and put every side effect behind a recorded workflow operation.

The runner drives the body until completion or suspension. Its ordinary event stream is named `wf:<name>-<id>` and decoded with `workflowJournalCodec`; generations opened by `continueAsNew` receive a generation suffix. A named `step` records its result and returns that result during replay instead of repeating the action.

`WorkflowOutcome` is `Completed a | Suspended | Cancelled | Failed | ContinuedAsNew`. `Failed` is terminal: the instance has exhausted its attempt budget and left resume discovery. Handle it deliberately — see [workflow reliability and recovery](workflow-reliability.md).

Workflow bodies must be deterministic outside recorded operations. Prefer stable explicit names such as `sleepNamed`; ordinal `sleep` labels can drift when control flow changes.

Snapshots are safe to combine with awakeables, children, and sleeps. An `awaitStep` miss consults the generation-scoped workflow step index before arming and suspending, so a completion journaled concurrently with a snapshotting run cannot be hidden by that snapshot.

## Deploy progress mechanisms by capability

The rule is one sentence: always run resumption for suspended workflows, schedule timer polling when using sleep, and deliver external awakeable signals where the integration occurs.

- `resumeWorkflowsOnceUpTo` is the bounded test and operations pass; `resumeWorkflowsOnce` retains the unbounded compatibility behavior. Use `runWorkflowResumeWorker`, `runWorkflowResumeWorkerWith`, or `runWorkflowResumeWorkerPush` for continuous service operation. Discovery is exact: only `running` instances and `suspended` instances with a due wake hint are returned, so parked awakeables, children, and future sleeps cost no resume passes. Its `ResumeSummary` reports `discovered`, `resumed`, `completed`, `stillSuspended`, `unknownName`, `failed`, `transientErrors`, and `leaseSkipped`; export all of them.
- The resume default is `maxConcurrentAdvances = 1`. Raise it only against store connection-pool headroom and make `logEvent` thread-safe when several candidates advance at once.
- `runWorkflowTimerWorker` is the compatibility one-row firing pass. Schedule timer polling when workflow bodies use `sleep` or `sleepNamed`, and use `drainWorkflowSleepTimers` or `drainDueTimersWith` for bounded backlog drains.
- `signalAwakeable` completes external waits idempotently and journals the result in the same transaction. It returns `False` without appending when cancellation won the race.
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

Rotation invalidates any awakeable id already handed to an external holder. The next generation re-runs the allocation step and produces a fresh id, so that step must notify the holder again.

A journaled step result is permanent. Never change the type a step decodes into: rename the step so it runs fresh, or guard the change with a stable `patch`. Put specification changes through the [keiro-dsl evolution gate](dsl-adoption.md) and the [rollout ordering rules](evolution-and-rollout.md) before deployment.

## Honor the custom wake-source contract

A custom wake source needs a durable logical-workflow row, delivery under the awaited step name, an await arm that re-checks and re-delivers after a rotation race, and an instance-row write on every resolution or abandonment transition. A terminal journal refusal settles the source row but delivers nothing. The complete recovery and arbitration rules live in [workflow reliability and recovery](workflow-reliability.md).

Deterministic workflow identities now hash UTF-8 seed bytes. ASCII ids are unchanged; non-ASCII seeds move without a migration and can cross the upgrade boundary with bounded at-least-once duplication. Never change the derivation or seed composition as an ordinary refactor.

For authoring, awaitables, children, and sleep semantics, see the keiro repo's `docs/user/durable-workflows.md` and `docs/guides/durable-workflows.md`.

## Related Patterns

- [Workflow reliability and recovery](workflow-reliability.md)
- [Runtime assembly](runtime-assembly.md)
- [Telemetry](telemetry.md)
- [Keiro-dsl adoption](dsl-adoption.md)
- [Keiro operations console](operations-console.md)
