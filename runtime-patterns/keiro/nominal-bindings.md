---
type: Standard
title: "Consumer-owned nominal bindings"
description: "Binding direct aggregate IDs, enums, and scalar wrappers to existing Haskell types with total isomorphisms, fixtures, and a decoder-tightening audit"
timestamp: 2026-07-31T16:04:17-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-nominal-bindings
tags: [keiro, nominal-bindings]
status: current
---

# Consumer-owned nominal bindings

**Bind a consumer-owned ID, enum, or scalar wrapper only when the conversion is a total isomorphism in both directions; anything that can reject or normalize a valid representation is `mapped opaque`, not nominal.**

A nominal binding keeps an application's existing type in direct aggregate commands, events, and registers without generating a parallel wrapper. It is the third mapping kind, alongside `mapped structural` and `mapped opaque`, and it requires [language version 2](language-versions.md).

## Choose nominal only for a total isomorphism

`Keiro.Codec.Nominal.NominalBinding domain representation` holds `nominalToRepresentation` and `nominalFromRepresentation`. Both are total functions and each must invert the other. The module lives in `keiro-core` and is re-exported from `keiro`, so a generated consumer keeps one direct dependency. The generated harness checks the two laws with `nominalDomainRoundTrip` and `nominalRepresentationRoundTrip` over a non-empty `NominalFixtureCases`.

A smart constructor that validates, rejects, canonicalizes, or trims is a *refined* type, not a nominal one. Its round trip is not an isomorphism and the binding laws will fail. Declare it `mapped opaque` and leave the consumer codec authoritative.

Fixtures are evidence, never proof: a finite corpus does not establish the laws for values outside its cases. Choose cases that cover each constructor, each boundary spelling, and every value shape production has actually stored.

## Declare the binding beside the type it binds

```text
id OrderId prefix=ord using {
  haskell package=orders-domain module=Orders.Id type=OrderId
  binding = "Orders.KeiroBindings.orderIdBinding"
  binding-version = "1"
  canonical-type = "orders.OrderId.v1"
  fixtures = "Orders.KeiroBindings.orderIdFixtures"
}

enum OrderStatus { Draft=draft Submitted=submitted } using {
  haskell package=orders-domain module=Orders.Order type=OrderStatus
  binding = "Orders.KeiroBindings.orderStatusBinding"
  binding-version = "1"
  canonical-type = "orders.OrderStatus.v1"
  fixtures = "Orders.KeiroBindings.orderStatusFixtures"
}

mapped nominal AccountNumber : Text {
  haskell package=orders-domain module=Orders.Account type=AccountNumber
  binding = "Orders.KeiroBindings.accountNumberBinding"
  binding-version = "1"
  canonical-type = "orders.AccountNumber.v1"
  fixtures = "Orders.KeiroBindings.accountNumberFixtures"
  initial = "Orders.KeiroBindings.initialAccountNumber"
}
```

Every ingredient is required and qualified. `check` reports a missing or malformed one under its own code — `NominalMissingIngredient`, `NominalInvalidHaskellSource`, `NominalInvalidQualifiedName`, `NominalInvalidIdentity`, `NominalInvalidIdPrefix`, `NominalUnsupportedRepresentation`, `NominalEmptyEnumRepresentation`, `NominalMissingInitialValue`, `NominalNameCollision` — before scaffolding writes anything.

The generated layer imports the application type. Do not introduce a second wrapper to satisfy the DSL.

## Know which representation each kind crosses

- A bound **ID** crosses a typed `KindID "prefix"`. The generated decoder validates the ID text and its prefix before constructing the consumer value. Bound IDs add `mmzk-typeid` to the generated package requirements.
- A bound **enum** crosses a generated closed private representation. Decoding admits only the declared wire spellings; an unknown spelling is rejected, never defaulted.
- A **nominal scalar** crosses exactly one of `Text`, `Int`, `Natural`, `Bool`, or `Time`.

## Meet the extra obligations a register carries

A bound type used as a register additionally requires an `initial` symbol and consumer `ToJSON`, `FromJSON`, and `CanonicalTypeName` instances, because the snapshot boundary remains a consumer-JSON cache rather than generated structural encoding. In the spec, a nominal register initial is written as the bare `initial` token; the declared symbol supplies the value.

## Know what a bound value can do in a guard

Bound scalar registers expose a generated context-level `NominalProjections` facade. Under version 2:

- equality is solver-visible for all five scalar representations;
- ordering is solver-visible only for `Int`, `Natural`, and `Time`;
- bound **IDs and enums cannot be compared at all** in a guard — their symbolic encoding is not structural, so `check` rejects the comparison rather than degrading it silently;
- nominal arithmetic does not exist. Arithmetic stays on direct `Integer` and `Natural`. See [aggregate scalar expressions](aggregate-expressions.md).

## Audit an adoption over existing history

Adding a checked binding to an ID that already appears in a stored event **tightens** historical decoding: payloads that decoded as free text before must now satisfy the typed prefix. The differ reports `NominalIdDecoderTightened` at every affected event use, as an advisory on `private-history-read` with a `consumer-build` advisory — a change to review, not a blocked deployment.

Discharge it before shipping:

1. Commit a genuine old-payload fixture that is valid under the new decoder.
2. Run the targeted replay audit for that event with `--replay-impact-out` and `AuditTargeted`.
3. Only then switch the binding on in production.

The other nominal diff codes carry the weight their surface implies: `NominalRepresentationChanged` is wire-breaking; `NominalBindingChanged` points at the binding laws, fixtures, and replay evidence because the change is not inspectable from spec text; `NominalInitialChanged` and `NominalCanonicalTypeChanged` reach the snapshot and consumer-build surfaces; `NominalFixturesChanged` records the evidence change. Branch on the code, never the sentence.

## Keep provenance in the record

Nominal consumer provenance is fingerprinted and diff-visible. Scaffold and workspace records persist it in additive `nominal-mapping` rows, so an older reader ignores them without disturbing existing `mapping` JSON. Generated binding skeletons are create-once: fill them, never regenerate over them.

## Related Patterns

- [Keiro DSL language versions](language-versions.md)
- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Keiro-dsl adoption](dsl-adoption.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Specification and scaffolding](../architecture/spec-and-scaffolding.md)
