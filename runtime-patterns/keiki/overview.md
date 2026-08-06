---
type: Overview
title: "Keiki Patterns for Keiro Runtime Projects"
description: "Index of Keiki transducer patterns for Keiro services; start here"
timestamp: 2026-08-06T02:47:25Z
generated:
  by: human:nadeem
  at: "2026-08-06T02:47:25Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-overview
tags: [keiki, overview]
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
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; changes requested: the release digest omits 0.3.1.0's CanonicalStateShape/stateShapeHash.
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
      Model re-review of the correction against the keiki changelog: the release digest now records 0.3.1.0's CanonicalStateShape/stateShapeHash.
---

# Keiki Patterns for Keiro Runtime Projects

**Start here for prescriptive Keiki 0.9 transducer, replay, validation, composition, and private-event guidance.**

This corpus is the terse, agent-facing standard for keiki-backed state machines inside keiro services. It covers pure aggregates and orchestrator transducers; the hosted process-manager runtime, durable timers, and cross-service messaging belong to keiro and the messaging standards tracked separately by this initiative.

## Start Here

- **[Keiki Transducer Best Practices](./transducer-best-practices.md)** is the primary authoring standard: use the builder DSL, declare output intent, emit every replay-critical field, validate the complete machine, and test replay.
- **[Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md)** is the migration sequence for existing 0.1 services, including compiler failures, new warnings, the one-time snapshot-hash change, and the removed Decider facade.

## Focused Guides

- **[Trusted Constructor Evidence](./constructor-evidence.md)** is the producer standard for `InCtor` and `WireCtor`: which `Via` builder to use, what evidence buys in composition, replay, and symbolic exclusion, and what silently drops it.
- **[Build-Time Validation](./build-time-validation.md)** documents the configurable soundness checks, the unconditional projection checks, the opaque-guard audit, Keiro's reject-on-warning boundary, solver escalation, and the `verifyPredicate` verification taxonomy.
- **[Typed Field Projections](./typed-field-projections.md)** explains when `regProj` and `inpProj` can expose decision scalars from consumer-owned records without flattening the model or losing symbolic checks.
- **[Exact Projection Domains](./exact-projection-domains.md)** is the only route from a conservatively classified projection back to a `Verified*` result: declare the complete image, the canonical inverse, and the owner-side conformance tests.
- **[Structured Replay and Hydration](./structured-replay-and-hydration.md)** covers `reconstituteEither`, resumable `replayEvents`, `InFlight`, and the complete structured failure taxonomy.
- **[Diagnosing Rejected Commands](./diagnosing-rejected-commands.md)** uses `stepEither` and `StepFailure` to distinguish normal refusal from ambiguous-transition defects.
- **[Event Schema Evolution](./event-schema-evolution.md)** gives the persisted-JSON playbook for missing-field defaults, stable wire kinds, in-band versions, and complete upcaster chains.
- **[Deriving JSON Codecs](./json-event-codecs.md)** documents the five generated bindings, all eight codec options, and the aeson-free core boundary.
- **[Checked Composition](./checked-composition.md)** defines safe sequential and alternative composition, poison provenance, and the stateless two-copy `feedback1` contract.
- **[Collections and Opaque Guards](./collections-and-opaque-guards.md)** explains why storing a collection is sound, content closures under-verify, and independently identified elements often need separate streams.
- **[Resolving Operator Conflicts](./operator-conflicts.md)** gives three import patterns for keiki's predicate operators alongside `lens` and `generic-lens`.
- **[Keiki Diagram Documentation](./diagram-docs.md)** generates and validates Mermaid atlases and edge inspectors from executable transducers.

## What Changed Through Keiki 0.9.0.0 (2026-08)

- Keiki 0.9 **seals `WireCtor` and `InCtor` construction**. Both are read-only patterns, so record literals and record updates no longer compile; trusted structural evidence comes only from the `mkInCtorVia` / `mkInCtorRecordVia` / `mkWireCtorVia` / `mkWireCtor0Via` / `mkWireCtorRecordVia` producers and Template Haskell derivation. `mkWireCtor`, `mkWireCtor0`, `mkInCtor`, and `mkInCtor0` are deprecated; `unavailableWireCtor` / `unavailableInCtor` are the explicit manual-behavior constructors and `renameWireCtor` / `renameInCtor` relabel without discarding evidence. See [Trusted Constructor Evidence](./constructor-evidence.md).
- Keiki 0.9 makes that evidence load-bearing in three places: sequential composition substitutes only through typed input-to-wire alignment and reports `StructurallyDifferentInputWire` or `UnwitnessedInputWireAlignment` instead of trusting equal names; the replay-inversion check proves heads distinct from structural constructor paths; and symbolic `PInCtor` translation keeps same-named trusted constructors distinct while collapsing unwitnessed equal names onto one conservative atom. Schema alignment no longer contains an `unsafeCoerce`. See [Checked Composition](./checked-composition.md).
- Keiki 0.9 **narrows the default `InversionAmbiguity` set**: a same-mode pair is suppressed when exact integral register-versus-literal conjuncts prove the two replay candidates disjoint. Unsupported and opaque guards stay conservative and name the blocking construct in `tvwDetail`. The opt-in `checkInversionAmbiguitySym` / `checkInversionAmbiguitySymDetailed` add an SBV analysis that removes a warning only on a uniquely matching definite UNSAT. Runtime replay is unchanged. See [Build-Time Validation](./build-time-validation.md).
- **Breaking:** nullary Template Haskell wires match structurally, so they require `Generic co` rather than `Eq co`; a quotienting custom `Eq` no longer changes `wcMatch`. `solveOutput` still requires `Eq co`. `keiki-codec-json` 0.9 is a bounds-only co-release with an unchanged wire format.
- Keiki 0.8 makes readable Mermaid the **default**: `toMermaid` and every no-options shape renderer now emit pretty guards, complete register assignments, multiline labels, and no truncation. `MermaidOptions` drops `showWrittenSlots` and `showGuardSummary` in favour of `updateMode` and `guardMode`; `toTopologyMermaid` and `topologyMermaidOptions` reproduce 0.7's compact bytes when a diagram is deliberately topology-only. Checked-in diagrams change on upgrade. See [Keiki Diagram Documentation](./diagram-docs.md).
- Keiki 0.8 requires `Show` on `lit`/`TLit` so renderers print real literal text, and adds `opaqueLit`/`TOpaqueLit` for values with no `Show`, secrets, and deliberate redactions. Both are breaking for exhaustive `Term` matches. See [Keiki Transducer Best Practices](./transducer-best-practices.md).
- Keiki 0.7 **narrows what a field projection proves**: a one-way `fieldWitness` no longer counts as exact merely because its result carrier is solver-supported, so existing projection callers now receive `UnverifiedOpaque` from `verifyPredicate`. `Keiki.ProjectionDomain`, `ExactFieldProjection`, `exactFieldWitness`, and the `checkFieldProjection*` laws are the supported way back to a proof. See [Exact Projection Domains](./exact-projection-domains.md).
- Keiki 0.7 makes `verifyPredicate` a compatibility projection of `verifyPredicateDetailed` and adds `predicateTranslationReport`, whose `TranslationIssue` list names exactly what cost the predicate its exactness. Only definite UNSAT under an exact translation is a proof. See [Build-Time Validation](./build-time-validation.md).
- Keiki 0.7 adds opt-in proof-relevant execution evidence: `stepDetailedEither`/`StepSuccess` for forward steps, and `applyEventsDetailedEither`/`reconstituteDetailedEither`/`ReplayAttribution` for an ordered completed-edge factorization of a replay. The existing functions keep their signatures and their O(1) no-trace policy. See [Structured Replay and Hydration](./structured-replay-and-hydration.md).
- Keiki 0.7 also makes `symSatExt` concretely recheck every reconstructed candidate, so a returned pair always satisfies `models`; `Nothing` still means "no witness recovered", never proof of unsatisfiability.
- Keiki 0.6 makes structural `Natural` subtraction **total monus** — `a - b = max 0 (a - b)`, lowered as `ite (a >= b) (a - b) 0` — in both concrete and symbolic evaluation. It is a breaking semantic fix: a `Natural` register decrement now clamps at zero instead of throwing `Underflow`. See [Keiki Transducer Best Practices](./transducer-best-practices.md).
- Keiki 0.6 adds `verifyPredicate`, `PredicateVerification`, and `predicateTranslationExact`, which keep an inexact translation and an indefinite solver answer distinguishable from a proof. See [Build-Time Validation](./build-time-validation.md).
- Keiki 0.6 moves `Natural` into the symbolic numeric registry, so the opt-in opaque audit no longer reports its arithmetic. That audit now covers any `TArith` whose carrier is *outside* the registry, not only `TApp` closures, and its detail text no longer names a constructor. See [Collections and Opaque Guards](./collections-and-opaque-guards.md).
- Keiki 0.5 admits `Natural` as a symbolic scalar with a pinned `CanonicalTypeName` and equality/ordering support, constrained non-negative wherever a symbolic variable is allocated. `Sym.constrainSymDomain` is the seam that states such a domain invariant; it has a default, so existing hand-written `Sym` instances still compile.
- Keiki 0.5 also applies that domain constraint to opaque fallbacks, so a term the translator cannot see through is now a fresh *domain-valid* variable rather than an unconstrained one — a soundness floor, not verification.
- Keiki 0.4 adds nominal, solver-visible `FieldProjection` witnesses over direct register and matched-input owners. They are guard-only, validated against the symbolic type registry, and designed for schema-derived generators such as Keiro-dsl. See [Typed Field Projections](./typed-field-projections.md).
- `validateTransducer` now adds three unconditional projection-integrity warnings to the seven configured soundness checks and the opt-in opaque audit. See [Build-Time Validation](./build-time-validation.md).
- `composeChecked` reports `NonStructuralProjectionBoundary` when composition would lower a structural getter to opaque application logic. See [Checked Composition](./checked-composition.md).
- Keiki 0.3 introduced `Live` and `ReplayOnly` edge modes so historical events remain invertible after a live guard changes. See [Structured Replay and Hydration](./structured-replay-and-hydration.md).
- Keiki 0.3.1.0 added `Keiki.Shape.CanonicalStateShape` with `stateShapeCanonical` and `stateShapeHash`, giving control-state snapshots a stable identity discriminator; Keiro 0.4's `StateCodec` requires it. See the [Keiro read-model and snapshot standard](../keiro/read-models-and-projections.md).

The Keiki 0.2 hardening remains foundational:

- `validateTransducer defaultValidationOptions` now runs seven soundness checks. Four new replay-safety warnings—`HeadUnrecoverable`, `InversionAmbiguity`, `UnguardedInputRead`, and `StateChangingEpsilon`—make previously latent hydration defects visible, and keiro's `mkEventStream` rejects any warning. See [Build-Time Validation](./build-time-validation.md).
- Every builder edge body must declare output intent with `emit`, `emitWith`, or `noEmit`. `buildTransducerEither` returns all located builder defects as values. See [Keiki Transducer Best Practices](./transducer-best-practices.md).
- Structured hydration is now the primary replay surface: `reconstituteEither`, `replayEvents`, `applyEventsEither`, `applyEventStreamingEither`, and `ReplayFailure` preserve exact failure positions and reasons. See [Structured Replay and Hydration](./structured-replay-and-hydration.md).
- `keiki-codec-json` now stamps an in-band `"v"`, supports pinned wire kinds, complete upcaster chains, and additive-field defaults through `fcOnMissing`. See [Event Schema Evolution](./event-schema-evolution.md).
- `composeChecked` reports boundary-name and field-position drift before construction, while poison provenance prevents categorical composition across non-invertible maps. See [Checked Composition](./checked-composition.md).
- Built-in canonical type names are now pinned and module-independent, so every non-empty register-file shape hash changes once; existing snapshots become benign cache misses followed by full replay. See [Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md).
- The lossy pre-release Decider facade is removed. Use `stepEither` for forward decisions and the structured replay functions for hydration. See [Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md).

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) is the normative authoring checklist.
- [Build-Time Validation](./build-time-validation.md) is the normative acceptance gate.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) is the normative hydration API guide.
- [Event Schema Evolution](./event-schema-evolution.md) is the normative private-event compatibility guide.
- [Typed Field Projections](./typed-field-projections.md) is the normative guide for decisions over consumer-owned values.
- [Exact Projection Domains](./exact-projection-domains.md) is the normative guide for proving anything about those decisions.
