# Guide

- [Build-Time Validation of Keiki Transducers](build-time-validation.md) - Asserting transducers and typed field projections are well-formed in CI with validateTransducer
- [Diagnosing Rejected Commands with `stepEither`](diagnosing-rejected-commands.md) - Using stepEither and StepFailure to learn why a command was rejected
- [Keiki Diagram Documentation](diagram-docs.md) - Generating Mermaid diagrams, atlas sections, and edge inspectors from transducers
- [Event Schema Evolution](event-schema-evolution.md) - Evolving persisted event JSON with in-band versions, pinned kinds, and upcaster chains
- [Deriving JSON Codecs for Keiki Event Sums](json-event-codecs.md) - Deriving kind-discriminated JSON codecs with keiki-codec-json
- [Resolving Keiki Operator Conflicts with `lens` / `generic-lens`](operator-conflicts.md) - Resolving the lens / generic-lens (.>) operator clash three ways
- [Structured Replay and Hydration](structured-replay-and-hydration.md) - Diagnosing hydration failures with reconstituteEither, replayEvents, and ReplayFailure
- [Upgrading to Keiki 0.2](upgrading-to-keiki-0-2.md) - Migration notes for keiki 0.2: noEmit, new validation warnings, snapshot-hash change, Decider removal

# Overview

- [Keiki Patterns for Keiro Runtime Projects](overview.md) - Index of Keiki transducer patterns for Keiro services; start here

# Pattern

- [Checked Composition](checked-composition.md) - Wiring transducers with composeChecked, structural projection boundaries, alternative, and the feedback1 stateless-only trap
- [Collections and Opaque Guards](collections-and-opaque-guards.md) - Modeling collections without losing solver verification through opaque guards
- [Typed Field Projections](typed-field-projections.md) - Using Keiki field witnesses to inspect consumer-owned values without opaque guards or flattened domain models

# Standard

- [Exact Projection Domains](exact-projection-domains.md) - Declaring a projection's complete image and canonical inverse so symbolic verification can return a proof instead of UnverifiedOpaque
- [Keiki Transducer Best Practices](transducer-best-practices.md) - Core rules for authoring Keiki transducers with the builder DSL

