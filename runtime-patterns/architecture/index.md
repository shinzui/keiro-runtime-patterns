# Overview

- [Keiro Service Architecture](overview.md) - Index of the keiro service architecture standard: packages, vertical slices, tests, scaffolding; start here

# Pattern

- [Extended Keiro-DSL Node Verticals](extended-node-verticals.md) - Where read models, process managers, workflows, routers, publishers, inboxes, queues, and contracts sit in the slice
- [Worked Conversation Vertical](worked-example-conversation.md) - Complete file listing of danwa's Conversation slice across all six packages

# Standard

- [Cross-Cutting Module Allowlist](cross-cutting-modules.md) - The closed allowlist of technical-layer modules and the domain-vs-technology division heuristic
- [Six Packages Per Deployed Service](service-packages.md) - The six-package split standard for deployed keiro services and its dependency rules
- [Specification And Scaffolding](spec-and-scaffolding.md) - Placing the .keiro spec at domain/<service>.keiro and running keiro-dsl scaffold idempotently
- [Test Layout](test-layout.md) - The per-package test-suite standard: four core suites, vertical Spec modules, migrations test-support
- [Vertical-Slice Modules](vertical-slice-modules.md) - The authoritative Generated.* + Holes vertical-slice module convention per domain concept

