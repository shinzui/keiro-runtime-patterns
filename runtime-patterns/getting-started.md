---
type: Navigation
title: "Getting started with the runtime patterns"
description: "Task-oriented routes into the prescriptive Keiro runtime standards"
timestamp: 2026-07-23T04:08:00Z
resource: mori://shinzui/keiro-runtime-patterns/docs/runtime-patterns-getting-started
tags: [navigation, runtime-patterns]
status: current
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
  apply the [build-time validation gate](keiki/build-time-validation.md).
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
  versions, defaults, and upcasters.
- **Evolving database schemas:** follow
  [migration authoring](migrations/authoring.md), then use the
  [migration operations runbook](migrations/operations.md) for verification and
  repair.
- **Structuring packages and modules:** use the
  [service-package standard](architecture/service-packages.md) and
  [vertical-slice module standard](architecture/vertical-slice-modules.md).
- **Configuring a service:** begin with the
  [Settei service standard](config/settei-service-standard.md), and use the
  [Settei CLI standard](config/settei-cli-standard.md) for command-line tooling.
- **Operating Kubernetes:** follow the
  [Kubernetes deployment standard](config/kubernetes-deployment.md) for config,
  secrets, probes, and rollout behavior.

The [generated catalog index](https://github.com/shinzui/keiro-runtime-patterns/blob/master/runtime-patterns/index.md)
lists every subject and concept when you need exhaustive discovery.
