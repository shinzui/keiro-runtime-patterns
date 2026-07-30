---
type: Overview
title: "Keiki Patterns for Keiro Runtime Projects"
description: "Index of Keiki transducer patterns for Keiro services; start here"
timestamp: 2026-07-29T18:11:55-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-overview
tags: [keiki, overview]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-28T19:53:40-07:00
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
    document_timestamp: 2026-07-29T18:11:55-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction against the keiki changelog: the release digest now records 0.3.1.0's CanonicalStateShape/stateShapeHash.
---

# Keiki Patterns for Keiro Runtime Projects

**Start here for prescriptive Keiki 0.4 transducer, replay, validation, composition, and private-event guidance.**

This corpus is the terse, agent-facing standard for keiki-backed state machines inside keiro services. It covers pure aggregates and orchestrator transducers; the hosted process-manager runtime, durable timers, and cross-service messaging belong to keiro and the messaging standards tracked separately by this initiative.

## Start Here

- **[Keiki Transducer Best Practices](./transducer-best-practices.md)** is the primary authoring standard: use the builder DSL, declare output intent, emit every replay-critical field, validate the complete machine, and test replay.
- **[Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md)** is the migration sequence for existing 0.1 services, including compiler failures, new warnings, the one-time snapshot-hash change, and the removed Decider facade.

## Focused Guides

- **[Build-Time Validation](./build-time-validation.md)** documents the configurable soundness checks, the unconditional projection checks, the opaque-guard audit, Keiro's reject-on-warning boundary, and solver escalation.
- **[Typed Field Projections](./typed-field-projections.md)** explains when `regProj` and `inpProj` can expose decision scalars from consumer-owned records without flattening the model or losing symbolic checks.
- **[Structured Replay and Hydration](./structured-replay-and-hydration.md)** covers `reconstituteEither`, resumable `replayEvents`, `InFlight`, and the complete structured failure taxonomy.
- **[Diagnosing Rejected Commands](./diagnosing-rejected-commands.md)** uses `stepEither` and `StepFailure` to distinguish normal refusal from ambiguous-transition defects.
- **[Event Schema Evolution](./event-schema-evolution.md)** gives the persisted-JSON playbook for missing-field defaults, stable wire kinds, in-band versions, and complete upcaster chains.
- **[Deriving JSON Codecs](./json-event-codecs.md)** documents the five generated bindings, all eight codec options, and the aeson-free core boundary.
- **[Checked Composition](./checked-composition.md)** defines safe sequential and alternative composition, poison provenance, and the stateless two-copy `feedback1` contract.
- **[Collections and Opaque Guards](./collections-and-opaque-guards.md)** explains why storing a collection is sound, content closures under-verify, and independently identified elements often need separate streams.
- **[Resolving Operator Conflicts](./operator-conflicts.md)** gives three import patterns for keiki's predicate operators alongside `lens` and `generic-lens`.
- **[Keiki Diagram Documentation](./diagram-docs.md)** generates and validates Mermaid atlases and edge inspectors from executable transducers.

## What Changed Through Keiki 0.4.0.0 (2026-07)

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
