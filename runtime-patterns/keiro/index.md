# Gotcha

- [Keiro gotchas](gotchas.md) - Shared-stream, global-lock, resource-effect, silent-workflow-failure, and bring-your-own Kafka traps

# Guide

- [Keiro-dsl adoption](dsl-adoption.md) - When to adopt keiro-dsl, its generated-code firewall, holes, CLI, and evolution gate
- [Durable workflows](durable-workflows.md) - Durable workflow journals, capability-based workers, stable steps, and evolution
- [The two-schema arrangement](two-schema-arrangement.md) - Separation of Kiroku store, Keiro framework, and application-owned PostgreSQL schemas

# Overview

- [Keiro runtime patterns](overview.md) - Index of prescriptive Keiro runtime and DSL standards; start here

# Standard

- [Command cycle and errors](command-cycle-and-errors.md) - Command hydration, decision, append, projection, and prescriptive error handling
- [Evolution gates and rollout ordering](evolution-and-rollout.md) - The five evolution gates, the replay-impact verdict and targeted audit, and durable-value rollout ordering
- [Read models and projections](read-models-and-projections.md) - Read-model registration, consistency, async fencing, rebuilds, and snapshot limits
- [Runtime assembly](runtime-assembly.md) - Store acquisition, validated event streams, resource effects, options, and startup order
- [Telemetry](telemetry.md) - Keiro tracing, metrics, W3C propagation, Kiroku bridging, and logging seams
- [Workflow reliability and recovery](workflow-reliability.md) - Lease sizing, the failure budget, terminal-failure resurrection, and the durable wake-source lifecycle

