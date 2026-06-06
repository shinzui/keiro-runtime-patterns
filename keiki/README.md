# Keiki Patterns for Keiro Runtime Projects

Practical guidance for building Keiki-backed transducers — aggregates, process-manager state
streams, and other durable state machines — inside Keiro services. Start with the best
practices, then reach for the focused guides as needed.

## Start here

- **[transducer-best-practices.md](./transducer-best-practices.md)** — the core rules:
  author with the builder DSL, use `step`, emit every replay-critical command field, keep
  registers small, validate at build time, and the new-transducer checklist. Read this first.

## Focused guides

- **[build-time-validation.md](./build-time-validation.md)** — assert your transducers are
  well-formed in CI. The `validateTransducer` umbrella (hidden inputs, determinism, dead
  edges), the structured warnings it returns, the opt-in opaque-guard audit, and the
  solver-backed variants for exact answers.
- **[diagnosing-rejected-commands.md](./diagnosing-rejected-commands.md)** — `stepEither` and
  `StepFailure`: learn *why* a command was rejected (no edges, no match, or ambiguity) instead
  of an opaque `Nothing`. Use it in command processors.
- **[collections-and-opaque-guards.md](./collections-and-opaque-guards.md)** — the most common
  modeling pitfall. Storing a collection is fine and verified; guarding on its contents through
  a closure silently loses verification. The audit flag and the sound alternatives. First-class
  collection registers are deferred — this explains the decision and the patterns to use today.
- **[diagram-docs.md](./diagram-docs.md)** — generate readable Mermaid diagrams, process-manager
  sections, edge inspectors, and validation tests from service-owned transducers.
- **[operator-conflicts.md](./operator-conflicts.md)** — resolving the `lens`/`generic-lens`
  `(.>)` clash three ways (hide-and-reimport, qualified `Keiki.Operators`, or the clash-free
  `B.requireGt` builder verbs).
- **[json-event-codecs.md](./json-event-codecs.md)** — deriving `kind`-discriminated JSON
  codecs for your private event sums with `keiki-codec-json`, with no silent generic fallback
  and the aeson-free-core boundary intact.

## What changed recently (2026-06)

These guides reflect the MasterPlan 14 round of Keiki improvements:

- Explainable execution (`stepEither`/`StepFailure`).
- The `validateTransducer` build-time umbrella plus determinism and dead-edge checks.
- Per-constructor TH derivation overrides (`deriveAggregateCtorsWith`/`deriveWireCtorsWith`).
- Readable Mermaid guards, multiline labels, typed atlas sections, edge inspectors, and diagram
  validation helpers.
- The `Keiki.Operators` qualified-import module for the operator clash.
- The `keiki-codec-json` event-codec skeleton.
- First-class collection registers: **prototyped and deferred (NO-GO)**; an opt-in
  `warnOpaqueGuards` audit now flags collection guards the solver can't see.
