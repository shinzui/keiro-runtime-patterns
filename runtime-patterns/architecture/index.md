# Overview

- [Keiro Service Architecture](overview.md) - Index of the keiro service architecture standard: domain types, packages, vertical slices, tests, and scaffolding; start here

# Pattern

- [Extended Keiro-DSL Node Verticals](extended-node-verticals.md) - Where read models, process managers, workflows, routers, publishers, inboxes, queues, and contracts sit in the slice
- [Worked Conversation Vertical](worked-example-conversation.md) - Complete file listing of danwa's Conversation slice across all six packages

# Standard

- [Cross-Cutting Module Allowlist](cross-cutting-modules.md) - The closed allowlist of technical-layer modules and the domain-vs-technology division heuristic
- [Domain Newtypes And TypeIDs](domain-newtypes-and-typeids.md) - Give every key domain value a nominal type, and use a TypeID-backed newtype for every service-owned identifier
- [The generated compilation contract](generated-compilation-contract.md) - The GHC2024 baseline, closed module extension set, generated service-wide evidence modules, and conformance/runtime-package authority
- [Six Packages Per Deployed Service](service-packages.md) - The six-package split standard for deployed keiro services and its dependency rules
- [Specification And Scaffolding](spec-and-scaffolding.md) - Placing a Keiro service source of truth, declaring mapped consumers, and running semantic-local whole-service check, scaffold, and conformance
- [Test Layout](test-layout.md) - The per-package test-suite standard, including structural mapping conformance and brownfield codec evidence
- [Vertical-Slice Modules](vertical-slice-modules.md) - The authoritative generated aggregate ring, structural mapping modules, and hand-owned holes/bindings convention

