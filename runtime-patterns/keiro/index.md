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

- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md) - Declaring typed guards and writes that generate the Keiki transducer, and marking the transitions that stay hand-owned
- [Behavior conformance and obligations](behavior-conformance.md) - Inventorying every live transition, rejection cell, and replay-only transition of a declared aggregate and proving each one with a typed witness
- [Command cycle and errors](command-cycle-and-errors.md) - Command hydration, decision, append, projection, and prescriptive error handling
- [Evolution gates and rollout ordering](evolution-and-rollout.md) - The six-layer evolution gate model, composed-workspace compatibility, structural mapping evidence, replay audits, and durable-value rollout ordering
- [Enforced identifier domains](identifier-domains.md) - The frozen TypeID-v7 admission contract for aggregate IDs from language version 3 and public contract fields from version 4, and the opposite rollouts they require
- [Keiro DSL language versions](language-versions.md) - Declaring an explicit language keiro-dsl preamble, adopting the stable version 4 contract, and auditing compatibility-only sources
- [Consumer-owned nominal bindings](nominal-bindings.md) - Binding direct aggregate IDs, enums, and scalar wrappers to existing Haskell types with total isomorphisms, fixtures, and a decoder-tightening audit
- [Read models and projections](read-models-and-projections.md) - Read-model registration, consistency, async fencing, rebuilds, and snapshot limits
- [Runtime assembly](runtime-assembly.md) - Store acquisition, validated event streams, structural mapping evidence, resource effects, options, and startup order
- [Composable service workspaces](service-workspaces.md) - Splitting one Keiro service into single-owner .keiro members while preserving whole-service checking, atomic scaffolding, adoption history, and evolution reports
- [Telemetry](telemetry.md) - Keiro tracing, metrics, W3C propagation, Kiroku bridging, and logging seams
- [Workflow reliability and recovery](workflow-reliability.md) - Lease sizing, the failure budget, terminal-failure resurrection, and the durable wake-source lifecycle

