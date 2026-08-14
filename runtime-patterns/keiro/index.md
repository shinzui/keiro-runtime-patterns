# Gotcha

- [Keiro gotchas](gotchas.md) - Shared-stream, global-lock, opaque-awakeable, structural-mapping, codec-authority, silent-workflow-failure, and bring-your-own Kafka traps

# Guide

- [Brownfield Keiro Adoption](brownfield-adoption.md) - Adopting Keiro around existing types and history with catalog ownership, codec evidence, full replay, and write-path parity gates
- [Keiro-dsl adoption](dsl-adoption.md) - When to adopt keiro-dsl, including workspaces, mapped consumer surfaces, semantic-local regeneration, the generated-code firewall, conformance, and evolution gates
- [Durable workflows](durable-workflows.md) - Durable workflow journals, at-least-once step effects, opaque awakeable publication, bounded progress workers, custom wakes, and evolution
- [The two-schema arrangement](two-schema-arrangement.md) - Separation of Kiroku store, Keiro framework, and application-owned PostgreSQL schemas

# Overview

- [Keiro runtime patterns](overview.md) - Index of the released Keiro 0.12.0.0 standards: projection catalogs, guarded external reads, stable DSL Language 5, durable workflows, and the operations console

# Runbook

- [Keiro operations console](operations-console.md) - Mounting and operating keiro-ops with schema checks, preview-before-force mutations, per-group operating rules, application hooks, and stable JSON

# Standard

- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md) - Declaring typed guards and writes that generate the Keiki transducer, and marking the transitions that stay hand-owned
- [Behavior conformance and obligations](behavior-conformance.md) - Inventorying every live transition, rejection cell, and replay-only transition of a declared aggregate and proving each one with a typed witness
- [Command cycle and errors](command-cycle-and-errors.md) - Command hydration, decision, append, projection, typed domain outcomes, and prescriptive error handling
- [Semantic-local Keiro DSL regeneration](dsl-semantic-locality.md) - Separating checked semantic consumers, generated-artifact churn, and source provenance while keeping service conformance complete
- [Evolution gates and rollout ordering](evolution-and-rollout.md) - The six-layer evolution gate model, composed-workspace compatibility, structural mapping evidence, replay audits, and durable-value rollout ordering
- [Enforced identifier domains](identifier-domains.md) - The frozen TypeID-v7 admission contract for aggregate IDs from language version 3 and public contract fields from version 4, and the opposite rollouts they require
- [Keiro DSL language versions](language-versions.md) - Declaring a Keiro DSL language contract, adopting published stable version 5, and auditing compatibility-only sources
- [Mapped consumer surfaces](mapped-consumer-surfaces.md) - Carrying mapped declarations through private events, snapshots, work queues, query contracts, and aggregate-sourced projections
- [Consumer-owned nominal bindings](nominal-bindings.md) - Binding direct aggregate IDs, enums, and scalar wrappers to existing Haskell types with total isomorphisms, fixtures, and a decoder-tightening audit
- [Typed projection catalogs and rebuild groups](projection-catalogs.md) - One validated projection inventory, guarded external read contracts, delivery-bound revision writers, and deterministic rebuilds
- [Read models and projections](read-models-and-projections.md) - Truthful read-model freshness, guarded external SQL contracts, catalog-backed projection application, targeted repair, and snapshot limits
- [Runtime assembly](runtime-assembly.md) - Store acquisition, validated event streams and projection catalogs, structural mapping evidence, resources, options, and startup order
- [Composable service workspaces](service-workspaces.md) - Splitting one Keiro service into single-owner members while preserving checked source provenance, semantic-local scaffolding, history, and evolution reports
- [Targeted stream-scoped projection repair](stream-scoped-repair.md) - Declaring a StreamScopedReplay policy and repairing one stream's projection rows under admission limits without a group rebuild
- [Telemetry](telemetry.md) - Keiro tracing, command-decision and position-distance metrics, W3C propagation, Kiroku bridging, and logging seams
- [TypeID prefix naming](typeid-prefix-naming.md) - Choose durable TypeID prefixes from the domain's ubiquitous language instead of an arbitrary abbreviation budget
- [Workflow reliability and recovery](workflow-reliability.md) - Exact wake discovery, bounded concurrent resume, terminal arbitration, failure recovery, and durable wake-source obligations

