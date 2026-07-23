---
type: Overview
title: "Keiki Patterns for Keiro Runtime Projects"
description: "Index of Keiki transducer patterns for Keiro services; start here"
timestamp: 2026-07-22T09:40:38-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-overview
tags: [keiki, overview]
status: current
---

# Keiki Patterns for Keiro Runtime Projects

**Start here for prescriptive keiki 0.2 transducer, replay, validation, composition, and private-event guidance.**

This corpus is the terse, agent-facing standard for keiki-backed state machines inside keiro services. It covers pure aggregates and orchestrator transducers; the hosted process-manager runtime, durable timers, and cross-service messaging belong to keiro and the messaging standards tracked separately by this initiative.

## Start Here

- **[Keiki Transducer Best Practices](./transducer-best-practices.md)** is the primary authoring standard: use the builder DSL, declare output intent, emit every replay-critical field, validate the complete machine, and test replay.
- **[Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md)** is the migration sequence for existing 0.1 services, including compiler failures, new warnings, the one-time snapshot-hash change, and the removed Decider facade.

## Focused Guides

- **[Build-Time Validation](./build-time-validation.md)** documents the seven default-on checks, all eight warning constructors, the opaque-guard audit, keiro's reject-on-warning boundary, and solver escalation.
- **[Structured Replay and Hydration](./structured-replay-and-hydration.md)** covers `reconstituteEither`, resumable `replayEvents`, `InFlight`, and the complete structured failure taxonomy.
- **[Diagnosing Rejected Commands](./diagnosing-rejected-commands.md)** uses `stepEither` and `StepFailure` to distinguish normal refusal from ambiguous-transition defects.
- **[Event Schema Evolution](./event-schema-evolution.md)** gives the persisted-JSON playbook for missing-field defaults, stable wire kinds, in-band versions, and complete upcaster chains.
- **[Deriving JSON Codecs](./json-event-codecs.md)** documents the five generated bindings, all eight codec options, and the aeson-free core boundary.
- **[Checked Composition](./checked-composition.md)** defines safe sequential and alternative composition, poison provenance, and the stateless two-copy `feedback1` contract.
- **[Collections and Opaque Guards](./collections-and-opaque-guards.md)** explains why storing a collection is sound, content closures under-verify, and independently identified elements often need separate streams.
- **[Resolving Operator Conflicts](./operator-conflicts.md)** gives three import patterns for keiki's predicate operators alongside `lens` and `generic-lens`.
- **[Keiki Diagram Documentation](./diagram-docs.md)** generates and validates Mermaid atlases and edge inspectors from executable transducers.

## What Changed In Keiki 0.2.0.0 (2026-07)

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
