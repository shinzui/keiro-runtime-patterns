---
type: Overview
title: "Keiro Service Architecture"
description: "Index of the keiro service architecture standard: packages, vertical slices, tests, scaffolding; start here"
timestamp: 2026-07-22T11:39:26-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-overview
tags: [architecture, overview]
status: current
---

# Keiro Service Architecture

**One vertical slice per domain concept, six packages per service, and one generated ring beside one hand-owned holes module.**

This area is the fleet structure standard for deployed keiro services. It reconciles danwa's shipped six-package, collocated module structure with the richer keiro-dsl node vocabulary in keiro-runtime-jitsurei. Danwa's code is authoritative where its older prose disagrees with it; keiro-runtime-jitsurei is the node-placement reference, but its teaching-only monolith and legacy duplicate modules are not production conventions.

## Start Here

- [Service packages](service-packages.md) defines the six cabal packages, their dependency boundaries, and the teaching-repository exception.
- [Vertical-slice modules](vertical-slice-modules.md) defines the per-concept generated and hand-owned module ring.
- [Specification and scaffolding](spec-and-scaffolding.md) places the `.keiro` source of truth and gives the repeatable regeneration workflow.
- [Cross-cutting modules](cross-cutting-modules.md) is the closed allowlist for technical module names.
- [Extended node verticals](extended-node-verticals.md) places read models, process managers, workflows, routers, queues, and integration contracts.
- [Test layout](test-layout.md) assigns test suites to packages and mirrors source verticals in test modules.
- [Worked Conversation example](worked-example-conversation.md) traces one real danwa concept across every package.

## How To Use This Standard

To lay out a new service, read service packages, vertical-slice modules, and specification and scaffolding in that order. To place a keiro-dsl node beyond an aggregate, use extended node verticals. When a proposed module has a technology-shaped name rather than a domain-concept name, check the cross-cutting allowlist; if the name is absent, keep the code in the owning concept vertical.

The generated/hand-owned boundary is load-bearing. Keiro-dsl may replace every `Generated.*` module, while developers own the corresponding holes and application modules. Never copy legacy parallel modules from a teaching repository into a deployed service.

## Related Patterns

- [Keiro-dsl adoption](../keiro/dsl-adoption.md)
- [Keiro runtime patterns](../keiro/overview.md)
- [Messaging patterns](../messaging/overview.md)
- [Migration package standard](../migrations/service-package.md)
