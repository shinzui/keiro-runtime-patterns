---
type: Navigation
title: "Getting started with the runtime patterns"
description: "Task-oriented routes into the prescriptive Keiro runtime standards"
timestamp: 2026-07-31T16:04:17-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/runtime-patterns-getting-started
tags: [navigation, runtime-patterns]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-28T19:53:40-07:00
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved the corpus's own routed documents and the keiro-dsl HEAD feature set; changes requested: no route reaches the new keiro/service-workspaces standard.
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T01:11:55Z
    document_timestamp: 2026-07-29T18:11:55-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction: the structuring route now reaches the composable service-workspace standard.
---

# Getting started with the runtime patterns

Choose the task that brought you here. Each route starts with the narrowest
normative document; follow its related links or the subject overview when you
need the surrounding rules.

- **Starting a new service:** begin with the
  [six-package service standard](architecture/service-packages.md), then use the
  [architecture overview](architecture/overview.md) for module and test layout.
- **Defining an aggregate:** begin with
  [Keiki transducer best practices](keiki/transducer-best-practices.md), then
  apply the [build-time validation gate](keiki/build-time-validation.md). When
  guards inspect fields of rich consumer-owned records, use the
  [typed field-projection pattern](keiki/typed-field-projections.md). When the
  aggregate is declared in a `.keiro` source, use
  [aggregate scalar expressions and transition ownership](keiro/aggregate-expressions.md)
  to decide what the spec generates and what stays hand-owned.
- **Writing or upgrading a `.keiro` source:** start with
  [Keiro DSL language versions](keiro/language-versions.md) to pick and declare
  the language contract; use
  [consumer-owned nominal bindings](keiro/nominal-bindings.md) when existing ID,
  enum, or scalar-wrapper types must appear in checked aggregate fields.
- **Adopting Keiro in an existing service:** follow
  [brownfield Keiro adoption](keiro/brownfield-adoption.md) to inventory stored
  bytes, map existing types, compare codecs, prove replay, and cut over without
  introducing a second wire authority.
- **Assembling the runtime:** follow
  [runtime assembly](keiro/runtime-assembly.md) for resource acquisition,
  validated streams, handlers, workers, and startup order.
- **Choosing a transport:** use the
  [transport-selection matrix](messaging/transport-selection.md) before adopting
  PGMQ, Kafka, or a Kiroku subscription.
- **Implementing process coordination:** start with the
  [process-manager standard](messaging/process-managers.md); use
  [durable workflows](keiro/durable-workflows.md) when the work is a stable,
  journaled sequence rather than event-driven orchestration.
- **Evolving persisted events:** follow
  [event-schema evolution](keiki/event-schema-evolution.md) for wire kinds,
  versions, defaults, and upcasters, then apply the
  [Keiro evolution gates](keiro/evolution-and-rollout.md).
- **Evolving database schemas:** follow
  [migration authoring](migrations/authoring.md), then use the
  [migration operations runbook](migrations/operations.md) for verification and
  repair.
- **Structuring packages and modules:** use the
  [service-package standard](architecture/service-packages.md) and
  [vertical-slice module standard](architecture/vertical-slice-modules.md); when
  several spec members compose one service, apply the
  [composable service-workspace standard](keiro/service-workspaces.md).
- **Configuring a service:** begin with the
  [Settei service standard](config/settei-service-standard.md), and use the
  [Settei CLI standard](config/settei-cli-standard.md) for command-line tooling.
- **Operating Kubernetes:** follow the
  [Kubernetes deployment standard](config/kubernetes-deployment.md) for config,
  secrets, probes, and rollout behavior.

The [generated catalog index](https://github.com/shinzui/keiro-runtime-patterns/blob/master/runtime-patterns/index.md)
lists every subject and concept when you need exhaustive discovery.
