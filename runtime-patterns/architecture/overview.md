---
type: Overview
title: "Keiro Service Architecture"
description: "Index of the keiro service architecture standard: domain types, packages, vertical slices, tests, and scaffolding; start here"
timestamp: 2026-09-06T21:22:15Z
generated:
  by: process:codex
  at: "2026-09-06T21:22:15Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-overview
tags: [architecture, overview]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T19:40:01Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved danwa and keiro-runtime-jitsurei reference applications and the keiro-dsl scaffolder at HEAD; verified exported symbols, signatures, version claims, and links.
---

# Keiro Service Architecture

**One nominal type per key domain value, one vertical slice per domain concept, six packages per service, and an explicit generated/hand-owned boundary for aggregate rings and structural mappings.**

This area is the fleet structure standard for deployed keiro services. It reconciles danwa's shipped six-package, collocated module structure with the richer keiro-dsl node vocabulary in keiro-runtime-jitsurei. Danwa's code is authoritative where its older prose disagrees with it; keiro-runtime-jitsurei is the node-placement reference, but its teaching-only monolith and legacy duplicate modules are not production conventions.

## Start Here

- [Domain newtypes and TypeIDs](domain-newtypes-and-typeids.md) makes TypeID the service-owned identifier default and forbids raw primitives for key domain values.
- [Service packages](service-packages.md) defines the six cabal packages, their dependency boundaries, and the teaching-repository exception.
- [Vertical-slice modules](vertical-slice-modules.md) defines the per-concept generated and hand-owned module ring.
- [Specification and scaffolding](spec-and-scaffolding.md) places the single-file or workspace service contract and gives the repeatable whole-service regeneration workflow.
- [The generated compilation contract](generated-compilation-contract.md) states how generated Haskell must be compiled: the GHC2024 baseline, the closed module-local extension set, the runtime-package authority, and the one conformance package a configured service scaffolds.
- [Generated Haskell editions](../keiro/generated-haskell-editions.md) governs explicit v2 adoption, record consumers, backup scope, and rollback.
- [Cross-cutting modules](cross-cutting-modules.md) is the closed allowlist for technical module names.
- [Extended node verticals](extended-node-verticals.md) places read models, process managers, workflows, routers, queues, and integration contracts.
- [Test layout](test-layout.md) assigns test suites to packages and mirrors source verticals in test modules.
- [Worked Conversation example](worked-example-conversation.md) traces one real danwa concept across every package.

## How To Use This Standard

To start a new service, establish its [domain newtypes and TypeIDs](domain-newtypes-and-typeids.md), then read service packages, vertical-slice modules, and specification and scaffolding in that order. To place a keiro-dsl node beyond an aggregate, use extended node verticals. When a proposed module has a technology-shaped name rather than a domain-concept name, check the cross-cutting allowlist; if the name is absent, keep the code in the owning concept vertical.

The generated/hand-owned boundary is load-bearing. Keiro-dsl may replace every `Generated.*` module, including structural wire shapes and projection witnesses, while developers own aggregate holes, consumer bindings, fixtures, and application modules. Never copy legacy parallel modules from a teaching repository into a deployed service.

## Related Patterns

- [Keiro-dsl adoption](../keiro/dsl-adoption.md)
- [Keiro runtime patterns](../keiro/overview.md)
- [Messaging patterns](../messaging/overview.md)
- [Migration package standard](../migrations/service-package.md)
- [Brownfield Keiro adoption](../keiro/brownfield-adoption.md)
- [Composable service workspaces](../keiro/service-workspaces.md)
