# Gotcha

- [Keiro gotchas](gotchas.md) - Shared-stream, global-lock, structural-mapping, codec-authority, silent-workflow-failure, and bring-your-own Kafka traps

# Guide

- [Brownfield Keiro Adoption](brownfield-adoption.md) - Adopting Keiro around existing domain types, stored JSON, and independent same-context scaffolds with workspace migration, codec evidence, and replay-safe cutover gates
- [Keiro-dsl adoption](dsl-adoption.md) - When to adopt keiro-dsl, including composable service workspaces, brownfield structural mappings, the generated-code firewall, conformance evidence, and evolution gates
- [Durable workflows](durable-workflows.md) - Durable workflow journals, capability-based workers, stable steps, and evolution
- [The two-schema arrangement](two-schema-arrangement.md) - Separation of Kiroku store, Keiro framework, and application-owned PostgreSQL schemas

# Overview

- [Keiro runtime patterns](overview.md) - Index of prescriptive Keiro runtime and DSL standards; start here

# Standard

- [Command cycle and errors](command-cycle-and-errors.md) - Command hydration, decision, append, projection, and prescriptive error handling
- [Evolution gates and rollout ordering](evolution-and-rollout.md) - The six-layer evolution gate model, composed-workspace compatibility, structural mapping evidence, replay audits, and durable-value rollout ordering
- [Read models and projections](read-models-and-projections.md) - Read-model registration, consistency, async fencing, rebuilds, and snapshot limits
- [Runtime assembly](runtime-assembly.md) - Store acquisition, validated event streams, structural mapping evidence, resource effects, options, and startup order
- [Composable service workspaces](service-workspaces.md) - Splitting one Keiro service into single-owner .keiro members while preserving whole-service checking, atomic scaffolding, adoption history, and evolution reports
- [Telemetry](telemetry.md) - Keiro tracing, metrics, W3C propagation, Kiroku bridging, and logging seams
- [Workflow reliability and recovery](workflow-reliability.md) - Lease sizing, the failure budget, terminal-failure resurrection, and the durable wake-source lifecycle

