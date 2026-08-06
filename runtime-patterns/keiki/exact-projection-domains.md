---
type: Standard
title: "Exact Projection Domains"
description: "Declaring a projection's complete image and canonical inverse so symbolic verification can return a proof instead of UnverifiedOpaque"
timestamp: 2026-08-03T02:56:33Z
generated:
  by: human:nadeem
  at: "2026-08-03T02:56:33Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-exact-projection-domains
tags: [keiki, exact-projection-domains]
status: current
---

# Exact Projection Domains

**A guard that crosses a field projection proves nothing until the projection declares its exact domain and a checked canonical inverse.**

Keiki 0.7 separates a projection that the translator can *see* from one it can *reason about*. The released `fieldWitness` constructor records only a total one-way getter, so from 0.7 every predicate that reads through it translates conservatively and `verifyPredicate` returns `UnverifiedOpaque`. `Keiki.ProjectionDomain` plus the `ExactFieldProjection` class is the only supported route back to a `Verified*` answer.

## Know Which Verification Strength A Guard Needs

Most guards need none of this. Concrete execution, replay, and `validateTransducer` are unchanged: a one-way witness still evaluates, still counts as a structural read, and still passes the unconditional projection checks. Declare an exact domain only when a test, a conformance report, or a rollout gate asserts a `Verified*` result over a predicate that reads a projected field.

Do not relabel a conservative answer. `UnverifiedOpaque` from a projection-crossing predicate is the correct classification, not a tooling defect; downstream conformance reporting must preserve it. See [build-time validation](build-time-validation.md) for the verification taxonomy.

## Declare The Complete Image, Not A Superset

`ProjectionDomain` has three forms:

- `finiteProjectionDomain :: NonEmpty a -> ProjectionDomain a` — a finite enumeration; duplicates are collapsed in first-occurrence order.
- `wholeProjectionDomain :: ProjectionDomain a` — the whole carrier. Use it only when `symbolicWholeCarrierExact @a` is `True`; symbolic *equality* support alone is not sufficient, because the representation must cover the concrete carrier bijectively.
- `textProjectionDomain :: TextPattern -> ProjectionDomain Text` — a validated full-string pattern.

Build a `TextPattern` with `textLiteral`, `textCharSet`, `textCharRanges`, `textConcat`, `textAlternation`, and `textRepeatBetween`. These return `Either DomainConstructionError` and are the only place the two interpretations are policed: `CodePointAboveSmtMaximum` rejects anything above `maximumSmtCodePoint` (U+2FFFF), `ReversedCharacterRange` an inverted range, and `InvalidRepetitionInterval` / `RepetitionBoundTooLarge` an unusable repetition bound. Never paper over the `Left` with a partial pattern. A text pattern always matches the complete `Text` value; there is no partial-match form.

A finite domain is constrained symbolically only when every literal round-trips through its symbolic representation and satisfies backend bounds. An unsupported domain emits no partial constraint — it degrades to a conservative translation rather than a wrong one.

A domain that is a strict superset of the real image weakens the proof but stays sound. A domain that *omits* a real owner key is unsound: it can make the solver report a false UNSAT. Owner-side conformance testing is mandatory whenever `exactFieldWitness` is used.

## Instantiate `ExactFieldProjection` For The Same Coherent Tag

Add the class to the tag that already carries the `FieldProjection` instance; do not introduce a second tag.

```haskell
instance ExactFieldProjection ArtifactKeyField where
  fieldProjectionDomain _ = artifactKeyDomain
  reconstructFieldOwner _ = parseArtifactInfoFromKey
```

Defining the instance changes nothing on its own. Call sites opt in per use:

```haskell
-- One-way, conservative: the released default.
artifactKeyWitness :: FieldWitness ArtifactKeyField
artifactKeyWitness = fieldWitness

-- Exact: carries the declared domain and inverse.
artifactKeyExactWitness :: FieldWitness ArtifactKeyField
artifactKeyExactWitness = exactFieldWitness
```

Use `fieldWitnessHasExactDomain` to assert which one a generated or imported binding actually carries. It is a read-only query; it cannot confer exactness.

## Test Both Declaration Laws

`checkFieldProjectionOwner` and `checkFieldProjectionKey` make the laws executable, and `ProjectionLawFailure` names the exact violation — `ProjectionWitnessIsUnconstrained`, `ProjectedKeyOutsideDeclaredDomain`, `ProjectionInverseRejectedDomainKey`, or `ProjectionInverseRoundTripMismatch`. No constructor stores the owner or key, so the failure is safe to log over sensitive values.

Cover both directions in every conformance suite:

```haskell
describe "artifact key projection is exact" do
  it "every domain member reconstructs" $
    for_ artifactKeyDomainMembers $ \key ->
      checkFieldProjectionKey artifactKeyExactWitness key `shouldSatisfy` isRight

  it "every generated owner lands in the domain" $
    forAll genArtifactInfo $ \owner ->
      checkFieldProjectionOwner artifactKeyExactWitness owner `shouldBe` Right ()
```

Enumerate every member for a finite domain. For a validated text domain, drive the owner direction from the same schema-derived generator that produces real values — the key direction cannot be enumerated, and Keiki cannot detect an omitted real key for you.

## Read The Detailed Result, Not Just The Compatibility One

`verifyPredicateDetailed` returns `PredicateVerificationDetail`, which reports the solver status, the `TranslationStrength`, and checked path-local `ProjectionModel` values. Use `projectionModelKeyAs` and `projectionModelOwnerAs` to recover typed values; never key off a descriptor's display name.

`PredicateProjectionContractViolation` means the solver produced an admitted key that the declared inverse rejected or that failed its getter round trip. That is a defect in the declaration, not an inconclusive solver answer — fix the domain or the inverse. The compatibility `verifyPredicate` folds it into `UnverifiedSolverFailure`, which is another reason to read the detailed result when exactness matters.

Keiki rechecks every satisfying model for domain membership, inverse success, and getter round trip before exposing it, and `symSatExt`'s final concrete recheck stays authoritative. A returned model is therefore always concretely valid; `Nothing` still means "no witness recovered", never proof of unsatisfiability.

## Do Not Mix Views Of One Owner

`predicateTranslationReport` reports `ConflictingProjectionViews` when one owner is read through tags that disagree, and `DirectAndProjectedOwnerRead` when the same predicate reads an owner both directly and through a projection. Both destroy exactness for the whole predicate. Pick one view of an owner per guard: either compare the whole value or compare through one canonical projection tag.

## Related Patterns

- [Typed Field Projections](typed-field-projections.md) defines the guard-only projection boundary these domains strengthen.
- [Build-Time Validation](build-time-validation.md) covers the verification taxonomy and the unconditional projection warnings.
- [Collections and Opaque Guards](collections-and-opaque-guards.md) explains the sound alternatives when no exact domain exists.
- [Consumer-owned nominal bindings](../keiro/nominal-bindings.md) and the [Keiro DSL language versions](../keiro/language-versions.md) describe the generated bindings that supply exact domains automatically.
