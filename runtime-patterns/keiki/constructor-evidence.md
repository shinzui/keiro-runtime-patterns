---
type: Standard
title: "Trusted Constructor Evidence"
description: "Minting InCtor and WireCtor values through trusted producers so composition, replay, and symbolic exclusion keep their proofs"
timestamp: 2026-08-06T02:47:25Z
generated:
  by: human:nadeem
  at: "2026-08-06T02:47:25Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-constructor-evidence
tags: [keiki, constructor-evidence]
status: current
---

# Trusted Constructor Evidence

**Mint every `InCtor` and `WireCtor` through a trusted producer; a manually built constructor carries no structural evidence and silently costs the pipeline its composition, replay, and exclusion proofs.**

From Keiki 0.9 a constructor is not just a name and a match/build pair. It also carries an abstract structural schema — the constructor's `Generic` sum path and its ordered, typed field spine — and only Keiki's own producers can mint one. Three separate analyses consult that schema instead of comparing diagnostic names. Author every boundary constructor so the schema is present.

## Construct Through A Producer, Never A Record

`InCtor` and `WireCtor` are sealed. The public `InCtor` and `WireCtor` names are read-only pattern synonyms over private constructors, so a record literal and a record update both fail to compile. Choose the producer by how the constructor is declared:

| Declaration | Input side | Wire side |
|---|---|---|
| Sum constructor wrapping a separate record value | `mkInCtorVia @"Name"` | `mkWireCtorVia @"Name"` |
| Sum constructor with fields declared directly in record syntax | `mkInCtorRecordVia @"Name"` | `mkWireCtorRecordVia @"Name"` |
| No-payload constructor | `mkInCtorVia @"Name"` | `mkWireCtor0Via @"Name"` |
| Template Haskell derivation | `deriveAggregateCtorsAll` | `deriveWireCtorsAll` |
| Behavior that is genuinely not structural | `unavailableInCtor` | `unavailableWireCtor` |

```haskell
-- CORRECT: trusted evidence from the carrier's Generic instance.
inCtorReserve :: InCtor CapacityCommand (RegFieldsOf ReserveIcuBedData)
inCtorReserve = mkInCtorVia @"ReserveIcuBed"

wireReserved :: WireCtor CapacityEvent (FieldsOf IcuBedReservedData)
wireReserved = mkWireCtorVia @"IcuBedReserved"

-- WRONG: a record literal no longer compiles, and would carry no evidence if it did.
-- wireReserved = WireCtor { wcName = "IcuBedReserved", wcMatch = ..., wcBuild = ... }
```

`mkInCtor`, `mkInCtor0`, `mkWireCtor`, and `mkWireCtor0` are deprecated. Their closure-taking interfaces cannot establish evidence, so they now delegate to the `unavailable*` constructors — they still compile and still behave correctly at runtime, but every analysis below silently falls back to its conservative path. Treat the deprecation warning as work, not noise.

Use `renameInCtor` and `renameWireCtor` when only the diagnostic name changes. They preserve behavior and evidence; the record update that used to do this is gone.

```haskell
-- CORRECT: relabel without discarding the structural schema.
wireReservedLegacy = renameWireCtor "IcuBedReserved_v1" wireReserved
```

## Know What Evidence Buys

Three analyses consult the schema. Each has a conservative fallback for unavailable evidence, so losing evidence degrades results rather than breaking a build — which is exactly why it goes unnoticed.

- **Sequential composition** substitutes mid-side fields and discharges constructor guards only through typed input-to-wire alignment. Equal diagnostic names no longer authorize a result-type coercion. Unavailable evidence produces an `UnwitnessedInputWireAlignment` warning; a genuine structural mismatch produces `StructurallyDifferentInputWire`. See [checked composition](./checked-composition.md).
- **Replay head aliasing** decides whether two outgoing edges can emit the same head event. With trusted schemas on both sides, structurally different constructor paths prove the heads distinct and no warning is raised. With either schema unavailable, the check falls back to comparing `wcName`. See [build-time validation](./build-time-validation.md).
- **Symbolic constructor exclusion** translates `PInCtor` through shared structural path decisions. Same-named trusted constructors stay distinct; unwitnessed equal names share one conservative fallback atom and contribute an `UnwitnessedInputConstructorIdentity` translation issue, which costs the predicate its exactness. Unequal names remain independent and therefore can never manufacture mutual exclusion.

## Do Not Expect A Profunctor Map To Carry Evidence

Schema-preserving composition retains evidence. A meaning-changing profunctor transformation drops it: `lmap`, `rmap`, and `dimap` rewrite match and build behavior, so the constructors they produce are built with `unavailable*` and stamped `#lmapped` or `#rmapped`. That is correct — the rewritten constructor no longer denotes the carrier's own `Generic` shape — but it means a mapped boundary is exactly where the conservative fallbacks apply. Keep maps outside composition boundaries, as [checked composition](./checked-composition.md) already requires for poison provenance.

## Observe The Relation Without Reading Names

When tooling needs the relation itself, use the proof-safe classifiers rather than comparing `icName` or `wcName`:

- `classifyWireHeads` — two wire constructors at one carrier.
- `classifyInputHeads` — two input constructors at one carrier.
- `classifyInputWireHeads` — an input constructor against an output wire constructor at the same carrier; this is the observer form of the alignment that authorizes composition substitution.

Each returns structurally-equal, structurally-different, or unwitnessed. Branch on the third case explicitly; collapsing it into either of the other two is the mistake the sealing exists to prevent.

## Understand Where Trust Bottoms Out

Trusted evidence roots in lawful `Generic` instances. A deliberately unlawful hand-written `Generic` can misrepresent a constructor's path or field spine and is outside the threat model, exactly as `unsafeCoerce` is. Derive `Generic`; do not hand-write it for a carrier that appears in a boundary constructor.

Schema alignment itself no longer contains an `unsafeCoerce`. Composition-only identity alignment carries a typed prefix spine and derives field equality by lockstep refinement, so the coercion that equal names used to justify is gone from the library.

## Migrate An Existing Aggregate

1. Compile against Keiki 0.9 and collect the deprecation warnings. Every `mkWireCtor`, `mkWireCtor0`, `mkInCtor`, and `mkInCtor0` call site is a boundary that lost its proofs.
2. Replace each with the `Via` producer matching its declaration shape. Use `mkInCtorRecordVia` and `mkWireCtorRecordVia` for constructors whose fields are declared inline — a multi-field inline constructor has no `mkInCtorVia` instance at all, and a single-field one resolves against the field's own type rather than the constructor's.
3. Replace any surviving record literal with `unavailableInCtor name match build` or `unavailableWireCtor name match build` only when the behavior is genuinely not structural, and record why.
4. Replace record updates that only relabel with `renameInCtor` / `renameWireCtor`.
5. Re-run `validateTransducer`. The `InversionAmbiguity` set can shrink once both heads carry trusted schemas; that is the intended result, not a regression.
6. Re-run `composeChecked` at every boundary and confirm no `UnwitnessedInputWireAlignment` warnings remain.

A nullary wire constructor changes constraint: `mkWireCtor0Via` matches structurally and requires `Generic co` where `mkWireCtor0` required `Eq co`. A carrier with a quotienting custom `Eq` therefore changes `wcMatch` behavior on migration — for the better, but verify it. `solveOutput` still requires `Eq co`.

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) is the authoring checklist these producers belong to.
- [Checked Composition](./checked-composition.md) consumes input-to-wire alignment at every sequential boundary.
- [Build-Time Validation](./build-time-validation.md) consumes head classification in the replay-inversion check and reports the unwitnessed-identity translation issue.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) explains the inverse information these constructors carry.
