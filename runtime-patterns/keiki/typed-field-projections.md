---
type: Pattern
title: "Typed Field Projections"
description: "Using Keiki 0.4 field witnesses to inspect consumer-owned values without opaque guards or flattened domain models"
timestamp: 2026-07-28T19:53:40-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-typed-field-projections
tags: [keiki, typed-field-projections]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-28T19:53:40-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; verified exported symbols, signatures, version claims, and links.
---

# Typed Field Projections

**Project a few decision scalars from rich domain values; keep the owner whole, the getter total, and the projection inside a guard.**

Keiki 0.4 adds `FieldProjection`, `FieldWitness`, `regProj`, and `inpProj`. They make a named scalar field of a consumer-owned record visible to concrete and symbolic guard evaluation without replacing that record with a generated type or hiding the getter in `TApp1`.

## Choose A Projection Only For Decision Facts

Keep the rich value whole when commands, events, registers, or read models need it. Project a scalar when a guard needs one stable fact such as an identity, revision, quantity, flag, timestamp, or content hash.

Prefer a separate scalar register when the fact is central to the aggregate, updated independently, or must appear in a solver-produced witness. A projection is a conservative scalar abstraction: the solver can reason about the projected result but cannot reconstruct an arbitrary owner value from it.

Do not use a projection to smuggle arbitrary application logic into the symbolic language. Collections, nested projection chains, computed owners, partial getters, updates, and outputs remain outside this feature.

## Prefer Schema-Derived Witnesses

Keiro-dsl generates one canonical projection tag and witness for each eligible scalar field of a `mapped structural` type. Import the generated `StructuralProjections` facade in the hand-owned holes module and use the witness the scaffolded transducer skeleton names. For readability, this example aliases the generated identifier locally as `artifactKeyWitness`:

```haskell
B.onCmd inCtorObserveArtifact $ \d -> B.do
  B.requireEq
    (inpProj artifactKeyWitness
      inCtorObserveArtifact #artifact)
    (regProj artifactKeyWitness
      (#currentArtifact :: Index ArtifactCatalogRegs ArtifactInfo))
  B.slot @"currentArtifact" =: d.artifact
  B.emit wireArtifactRecorded ArtifactRecordedTermFields
    { artifact = d.artifact }
  B.goto Observed
```

Use the actual import and name inserted by the scaffolded hole rather than guessing it. The generator derives each getter from the same resolved structural binding graph used by the event codec and exercises `fieldWitnessAgrees` over the declared fixtures.

For a hand-written integration, define one fresh nominal tag per logical field, give it one coherent `FieldProjection` instance, construct the token with `fieldWitness`, and test the getter with `fieldWitnessAgrees`. Reuse that tag everywhere the same field occurs. Duplicate tags are sound but reduce proof precision because the solver treats them as unrelated values.

## Respect The Direct-Base And Guard-Only Boundary

`regProj` may read only a direct register slot. `inpProj` may read only one field of a matched input constructor, and its guard must establish that constructor just like an ordinary `TInpCtorField` read. An arbitrary computed term cannot masquerade as a structural owner.

Projections are valid only in predicates. Continue to copy the whole owner value in an update or event output:

```haskell
-- Guard: project the scalar decision fact.
B.requireEq
  (inpProj contentHashWitness inCtorObserve #document)
  (regProj contentHashWitness #currentDocument)

-- Update and output: preserve the ordinary whole-value replay contract.
B.slot @"currentDocument" =: d.document
B.emit wireDocumentObserved DocumentObservedTermFields
  { document = d.document }
```

`validateTransducer` rejects a projection outside a guard with `ProjectionOutsideGuard`. It also reports `ProjectionResultUnsupported` when the result has no symbolic equality support and `ProjectionOrderingUnsupported` when an ordered comparison uses a result outside the narrower ordering registry. Generated Keiro witnesses are emitted only for eligible scalar fields, but the validation gate remains mandatory.

## Keep Checked Composition Structural

Composition preserves a projection when substitution leaves a direct register or input base, and it folds a projection whose owner becomes a literal. A computed upstream value or pending write lowers the getter to opaque `TApp1` logic. Raw `compose` preserves forward behavior in that case, but `composeChecked` reports `NonStructuralProjectionBoundary` and refuses to certify the pipeline.

Treat that warning as a modeling boundary: expose the fact as an explicit scalar, move the decision before the computed boundary, or keep the machines on separate runtime streams.

## Related Patterns

- [Keiki Transducer Best Practices](transducer-best-practices.md)
- [Build-Time Validation](build-time-validation.md)
- [Checked Composition](checked-composition.md)
- [Collections and Opaque Guards](collections-and-opaque-guards.md)
- [Brownfield Keiro Adoption](../keiro/brownfield-adoption.md)
