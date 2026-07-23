---
type: Guide
title: "Durable workflows"
description: "Durable workflow journals, capability-based workers, stable steps, and evolution"
timestamp: 2026-07-22T10:49:54-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-durable-workflows
tags: [keiro, durable-workflows]
status: current
---

# Durable workflows

**Workflow journals resume deterministically; deploy each progress mechanism the workflow actually uses.**

This guide orients service owners to keiro's durable workflow runtime while leaving authoring details to the upstream workflow guides.

## Run and replay the journal

The rule is one sentence: invoke `runWorkflowWith options name workflowId body` and put every side effect behind a recorded workflow operation.

The runner drives the body until completion or suspension. Its ordinary event stream is named `wf:<name>-<id>` and decoded with `workflowJournalCodec`; generations opened by `continueAsNew` receive a generation suffix. A named `step` records its result and returns that result during replay instead of repeating the action.

Workflow bodies must be deterministic outside recorded operations. Prefer stable explicit names such as `sleepNamed`; ordinal `sleep` labels can drift when control flow changes.

## Deploy progress mechanisms by capability

The rule is one sentence: always run resumption for suspended workflows, schedule timer polling when using sleep, and deliver external awakeable signals where the integration occurs.

- `resumeWorkflowsOnce` is the testable single pass. Use `runWorkflowResumeWorker`, `runWorkflowResumeWorkerWith`, or `runWorkflowResumeWorkerPush` for continuous service operation.
- `runWorkflowTimerWorker` is a one-pass timer firing action. Schedule or poll it when workflow bodies use `sleep` or `sleepNamed`.
- `signalAwakeable` completes external waits idempotently and journals the result in the same transaction.
- `runWorkflowGcWorker` is optional retention housekeeping for terminal instances. Configure it from a deliberate `WorkflowGcPolicy`; it is not required for workflow progress.

Nest defaults through lenses:

```haskell
resumeOptions metrics =
  defaultWorkflowResumeOptions
    & #runOptions .~
        (defaultWorkflowRunOptions & #metrics .~ metrics)
```

## Evolve live definitions deliberately

Stable recorded names are compatibility contracts. Use `patch` for a cross-cutting branch that in-flight instances must remember, and `continueAsNew` to rotate long-lived state into a fresh generation. Put specification changes through the [keiro-dsl evolution gate](dsl-adoption.md) before deployment.

For authoring, awaitables, children, and sleep semantics, see the keiro repo's `docs/user/durable-workflows.md` and `docs/guides/durable-workflows.md`.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Telemetry](telemetry.md)
- [Keiro-dsl adoption](dsl-adoption.md)
