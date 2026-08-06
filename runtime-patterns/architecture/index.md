# Overview

- [Keiro Service Architecture](overview.md) - Index of the keiro service architecture standard: packages, vertical slices, tests, scaffolding; start here

# Pattern

- [Extended Keiro-DSL Node Verticals](extended-node-verticals.md) - Where read models, process managers, workflows, routers, publishers, inboxes, queues, and contracts sit in the slice
- [Worked Conversation Vertical](worked-example-conversation.md) - Complete file listing of danwa's Conversation slice across all six packages

# Standard

- [Cross-Cutting Module Allowlist](cross-cutting-modules.md) - The closed allowlist of technical-layer modules and the domain-vs-technology division heuristic
- [The generated compilation contract](generated-compilation-contract.md) - The GHC2024 baseline generated Haskell compiles under, the closed extension set a module may request locally, and the conformance package and runtime-package authority a configured service scaffolds
- [Six Packages Per Deployed Service](service-packages.md) - The six-package split standard for deployed keiro services and its dependency rules
- [Specification And Scaffolding](spec-and-scaffolding.md) - Placing a single-file or workspace Keiro source of truth, declaring consumer mappings, and running whole-service check/scaffold/conformance idempotently
- [Test Layout](test-layout.md) - The per-package test-suite standard, including structural mapping conformance and brownfield codec evidence
- [Vertical-Slice Modules](vertical-slice-modules.md) - The authoritative generated aggregate ring, structural mapping modules, and hand-owned holes/bindings convention

