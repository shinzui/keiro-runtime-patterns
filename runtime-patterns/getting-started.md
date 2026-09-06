---
type: Navigation
title: "Getting started with the runtime patterns"
description: "Task-oriented routes into the prescriptive Keiro runtime standards"
timestamp: 2026-09-06T21:22:15Z
generated:
  by: process:codex
  at: "2026-09-06T21:22:15Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/runtime-patterns-getting-started
tags: [navigation, runtime-patterns]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T02:53:40Z
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
    document_timestamp: 2026-07-30T01:11:55Z
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

- **Starting a new service:** begin with
  [domain newtypes and TypeIDs](architecture/domain-newtypes-and-typeids.md), then apply the
  [six-package service standard](architecture/service-packages.md) and use the
  [architecture overview](architecture/overview.md) for module and test layout.
- **Defining an aggregate:** begin with
  [Keiki transducer best practices](keiki/transducer-best-practices.md), then
  apply the [build-time validation gate](keiki/build-time-validation.md). Mint every
  hand-written command and event constructor through
  [trusted constructor evidence](keiki/constructor-evidence.md), which is also the
  upgrade path for an aggregate still calling the deprecated `mkWireCtor` family. When
  guards inspect fields of rich consumer-owned records, use the
  [typed field-projection pattern](keiki/typed-field-projections.md), and add
  [exact projection domains](keiki/exact-projection-domains.md) when a gate must
  prove something about a projected guard rather than merely execute it. When the
  aggregate is declared in a `.keiro` source, use
  [aggregate scalar expressions and transition ownership](keiro/aggregate-expressions.md)
  to decide what the spec generates and what stays hand-owned.
- **Writing or upgrading a `.keiro` source:** start with
  [workspace-first service contracts](keiro/service-workspaces.md): use one
  versioned workspace by default, keep each aggregate in a readable single-owner
  member, and reserve a bare source for a trivial domain with exactly one
  aggregate. Then read
  [Keiro DSL language versions](keiro/language-versions.md) to pick and declare
  the language contract. On stable Language 5, follow
  [semantic-local regeneration](keiro/dsl-semantic-locality.md) and inventory
  every [mapped consumer surface](keiro/mapped-consumer-surfaces.md); use
  [consumer-owned nominal bindings](keiro/nominal-bindings.md) when existing ID,
  enum, or scalar-wrapper types must appear in checked aggregate fields; and
  [enforced identifier domains](keiro/identifier-domains.md) before moving a
  prefix-bearing ID onto version 3. Choose every new prefix with the
  [TypeID prefix naming standard](keiro/typeid-prefix-naming.md); do not impose
  an arbitrary abbreviation budget.
- **Upgrading generated Haskell or the keiro-dsl package API:** follow
  [generated Haskell editions](keiro/generated-haskell-editions.md) for the
  explicit migration, hand-owned record audit, Cabal reconciliation, and rollback.
  Keep this separate from the source-language declaration.

- **Proving an aggregate behaves as declared:** use
  [behavior conformance and obligations](keiro/behavior-conformance.md) to
  inventory every transition, rejection, and replay-only edge and gate CI on the
  generated report.
- **Adopting Keiro in an existing service:** follow
  [brownfield Keiro adoption](keiro/brownfield-adoption.md) to inventory stored
  bytes, map existing types, compare codecs, prove replay, and cut over without
  introducing a second wire authority.
- **Assembling the runtime:** follow
  [runtime assembly](keiro/runtime-assembly.md) for resource acquisition,
  validated streams, handlers, workers, and startup order. Build read-side
  ownership through [typed projection catalogs](keiro/projection-catalogs.md).
- **Serving and evolving the read side:** declare freshness and publish external
  SQL access through [read models and projections](keiro/read-models-and-projections.md);
  choose between the offline, schema-versioned, and
  [targeted stream](keiro/stream-scoped-repair.md) lifecycles before touching a
  serving target.
- **Protecting a long replay:** hold a
  [Kiroku replay-history retention lease](kiroku/history-retention.md) for the
  whole run, and abandon rather than reacquire when it lapses.
- **Inspecting or repairing a live runtime:** use the
  [Keiro operations console](keiro/operations-console.md) so schema checks,
  previews, stable JSON, bounded passes, and application-owned hooks wrap the
  supported lifecycle APIs.
- **Choosing a transport:** use the
  [transport-selection matrix](messaging/transport-selection.md) before adopting
  PGMQ, Kafka, or a Kiroku subscription. For PGMQ, also apply the
  [queue lifecycle and reconciliation standard](messaging/pgmq-queue-reconciliation.md).
- **Implementing process coordination:** start with the
  [process-manager standard](messaging/process-managers.md); use
  [durable workflows](keiro/durable-workflows.md) when the work is a stable,
  journaled sequence rather than event-driven orchestration.
- **Inspecting subscription progress:** read the public
  [Kiroku durable checkpoint inventory](kiroku/checkpoint-inventory.md), keeping
  member rows and global-position distance distinct from live worker state and
  event lag.
- **Evolving persisted events:** follow
  [event-schema evolution](keiki/event-schema-evolution.md) for wire kinds,
  versions, defaults, and upcasters, then apply the
  [Keiro evolution gates](keiro/evolution-and-rollout.md).
- **Evolving database schemas:** follow
  [migration authoring](migrations/authoring.md), then use the
  [migration operations runbook](migrations/operations.md) for verification and
  repair.
- **Structuring packages and modules:** start with the
  [workspace-first service-contract standard](keiro/service-workspaces.md), then use the
  [service-package standard](architecture/service-packages.md) and
  [vertical-slice module standard](architecture/vertical-slice-modules.md). Satisfy
  [the generated compilation contract](architecture/generated-compilation-contract.md)
  when wiring the generated layer into Cabal, naming the runtime package, or
  building the generated conformance package.
- **Configuring a service:** begin with the
  [Settei service standard](config/settei-service-standard.md), and use the
  [Settei CLI standard](config/settei-cli-standard.md) for command-line tooling.
- **Operating Kubernetes:** follow the
  [Kubernetes deployment standard](config/kubernetes-deployment.md) for config,
  secrets, probes, and rollout behavior.

The [generated catalog index](https://github.com/shinzui/keiro-runtime-patterns/blob/master/runtime-patterns/index.md)
lists every subject and concept when you need exhaustive discovery.
