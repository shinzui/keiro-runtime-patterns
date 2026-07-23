# ADR 0006: Separate pattern, product, and general Haskell documentation

## Status

Accepted — 2026-07-22

## Context

The Keiro ecosystem has three documentation repositories with overlapping audiences. Without an ownership boundary, the same operational rule can be copied into several places, drift independently, and leave developers or agents unsure which version is normative.

`keiro-runtime-patterns` is a terse, prescriptive corpus optimized for implementation and agent discovery through Mori. `keiro-runtime-docs` is the polished, product-organized Fumadocs website. `haskell-jitsurei` contains general Haskell practices that remain useful outside Keiro, including Servant API, OpenTelemetry, logging, pagination, and health-probe standards.

## Decision

Keep runtime-specific implementation standards in `keiro-runtime-patterns`, product explanations and navigation in `keiro-runtime-docs`, and generally applicable Haskell standards in `haskell-jitsurei`.

Cross-link or cite the owning document instead of duplicating its normative content. Register implementation-facing documents with Mori so tools and agents can discover the current owner. A product-site rewrite or synchronization project is separate work and must not silently become part of a runtime-pattern change.

## Consequences

- Each rule has one normative maintenance location.
- Blueprint references can cite stable Mori project and DocRef identities instead of embedding another copy of the corpus.
- Product documentation may explain and organize the standards for a broader audience without becoming their implementation source of truth.
- General Haskell guidance remains reusable by services that do not use Keiro.
- Cross-repository changes must name the owning repository and use links or citations at the boundary.

## Alternatives Considered

**Copy every rule into all three repositories.** Rejected because fixes and release corrections would have to land atomically across unrelated documentation systems.

**Make the product website the only source.** Rejected because its product-oriented structure and large MDX surface are not the terse, locally searchable contract needed by coding agents.

**Move all Haskell guidance into Keiro patterns.** Rejected because API and operational practices such as Servant problem details and Kubernetes probes apply beyond the Keiro runtime.

## Related Guidance

- [OKF runtime corpus adoption](0008-adopt-okf-for-the-runtime-pattern-corpus.md)
- [Keiro runtime standards MasterPlan](../masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md)
- [Seihou blueprint refresh](../plans/9-refresh-the-seihou-blueprints-to-encode-the-standards.md)
