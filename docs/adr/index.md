---
okf_version: "0.2"
---

# Files

- [profile.dhall](profile.dhall)

# Architecture Decision Record

- [Separate Kiroku, Keiro, and application schemas](0001-separate-kiroku-keiro-and-application-schemas.md) - Keep Kiroku's event-store schema, Keiro's framework schema, and application schemas separate instead of sharing one namespace or relying on search_path.
- [Adopt keiro-dsl for contracts and evolution](0002-adopt-keiro-dsl-for-contracts-and-evolution.md) - Adopt keiro-dsl to check cross-node contracts and generate structural wiring for services with multiple node families, integration surfaces, or evolving schemas.
- [Select PGMQ and Kafka by failure semantics](0003-pgmq-vs-kafka-transport-selection.md) - Use PGMQ for in-context jobs needing DLQ, retry, and lease semantics, and Kafka for cross-context event streaming, reserving Kiroku subscriptions for local event-log reactions.
- [Standardize six-package Generated/Holes verticals](0004-standardize-six-package-generated-holes-verticals.md) - Standardize every deployed Keiro service on six cabal packages with a keiro-dsl Generated ring and a hand-owned Holes module per aggregate.
- [Adopt settei for fleet configuration](0005-adopt-settei-for-fleet-configuration.md) - Adopt the settei package family as the typed, source-precedence configuration standard for new and materially refactored Keiro services and CLIs.
- [Separate pattern, product, and general Haskell documentation](0006-separate-pattern-product-and-general-haskell-docs.md) - Assign runtime-specific standards, product documentation, and general Haskell guidance to three distinct repositories, each with one normative owner.
- [Scope runtime standards to Kiroku, not Kioku](0007-scope-runtime-standards-to-kiroku-not-kioku.md) - Scope the Keiro runtime standards corpus to the Kiroku event store and exclude the unrelated Kioku agent-memory library.
- [Adopt OKF for the runtime pattern corpus](0008-adopt-okf-for-the-runtime-pattern-corpus.md) - Move the runtime-patterns corpus into one profiled OKF bundle with Mori-registered concepts, generated indexes, and scoped update logs.

