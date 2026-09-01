---
type: Standard
title: "Domain Newtypes And TypeIDs"
description: "Give every key domain value a nominal type, and use a TypeID-backed newtype for every service-owned identifier"
timestamp: 2026-09-01T16:07:10Z
generated:
  by: human:nadeem
  at: "2026-09-01T16:07:10Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-domain-newtypes-and-typeids
tags: [architecture, domain-types, newtype, typeid, identity]
status: current
---

# Domain Newtypes And TypeIDs

**Give every key domain value its own nominal type, and make every service-owned identifier a TypeID-backed newtype; raw `Text`, `String`, `Int`, `Integer`, and similar primitives are boundary representations, not domain types.**

The domain model must make accidental substitution a type error. If two values have different meanings even though they share a wire or storage representation, they have different Haskell types. A type synonym does not create that separation.

## Make TypeID The Identifier Default

Every new service-owned entity, aggregate, command, event, message, workflow, inbox, and outbox identity uses a prefix-bearing TypeID. Give the value a domain-specific newtype even when the underlying `KindID` already carries the prefix at the type level:

```haskell
newtype OrderId = OrderId (KindID "order")
  deriving stock (Eq, Ord)

newtype CommandId = CommandId (KindID "command")
  deriving stock (Eq, Ord)
```

Prefer `KindID "prefix"` to an unindexed TypeID in hand-owned code, so the compiler rejects a value from the wrong prefix before runtime. Use the full singular ubiquitous-language prefix from [TypeID prefix naming](../keiro/typeid-prefix-naming.md), mint UUIDv7 values for allocated domain identities, and admit parsed values through the checked contract in [enforced identifier domains](../keiro/identifier-domains.md). A deterministic technical identity follows the derivation and UUID version named by its owning runtime standard; never present a UUIDv5-derived value as a UUIDv7 identity. Do not store a TypeID-shaped value as `Text` inside the domain and rely on naming conventions or call-site discipline.

Keiro-generated aggregate IDs and contract `typeid` fields already supply the nominal wrapper and checked TypeID domain. Use those generated types directly; do not add a second application wrapper around them. When a hand-owned identifier is retained through a nominal binding, the hand-owned newtype is the one domain type and the binding connects it to Keiro's generated representation.

## Wrap Every Key Domain Scalar

Use `newtype` for a domain concept with one representation, a closed sum for alternatives, and a record for a multi-field value:

```haskell
newtype AccountNumber = AccountNumber Text
newtype TransferAmount = TransferAmount Natural
newtype Revision = Revision Natural

data Transfer = Transfer
  { source :: AccountId
  , destination :: AccountId
  , amount :: TransferAmount
  , expectedRevision :: Revision
  }
```

This rule applies to identifiers, names, codes, addresses, quantities, amounts, versions, sequence numbers, and other values whose meaning or invariants matter to a domain decision. It also applies when the current invariant is only documentary: the type preserves the concept and gives later validation one owning boundary.

Do not substitute any of these weaker shapes:

```haskell
type AccountId = Text       -- only an alias
type TransferAmount = Int   -- freely interchangeable with every Int

data Transfer = Transfer
  { source :: Text
  , destination :: Text
  , amount :: Int
  }
```

Raw primitives remain appropriate for incidental local calculations and for explicit wire, database, and library-adapter records. Convert at the boundary and keep the domain side nominal.

## Put Validation At Construction

Hide a constructor whenever the type has an invariant. Export a total smart constructor for values that cannot fail, or a parser/refining constructor whose failure is data. Decode HTTP, JSON, database, CLI, and message inputs into the domain type once; do not pass a primitive inward and repeatedly revalidate it.

Derive only operations that make domain sense. `Eq`, `Ord`, and a deliberate renderer are common. Do not derive `Num`, `Integral`, `IsString`, or enumeration behavior merely because the representation supports it: those instances recreate primitive interchangeability and can admit invalid values. Keep unwrapping functions at codecs and adapters instead of making them the default application vocabulary.

## Keep Boundary Representations Stable

A newtype does not require a wire-format change. A codec may continue to encode an `AccountNumber` as JSON text or a `Revision` as a JSON number while the application gains nominal safety. For persisted values, prove byte compatibility before replacing a primitive field with a wrapper.

Changing an existing identity from arbitrary text, UUID, integer, or a natural key to TypeID is different: it changes the admitted domain and may change durable values. Inventory readers and writers, retain the old replay path where required, and use the compatibility and rollout rules in [enforced identifier domains](../keiro/identifier-domains.md) and [evolution gates](../keiro/evolution-and-rollout.md). Do not smuggle that migration into an otherwise representation-preserving newtype refactor.

## Name The Exceptions

The TypeID default has only explicit boundary exceptions:

- an identifier allocated by an external authority or fixed protocol keeps that authority's representation;
- an opaque ID type owned by Keiro or another runtime is used directly at that boundary rather than rewrapped or flattened to a primitive;
- a natural or composite key remains a locator rather than being relabelled as an entity identity; and
- a transient index or count is not an identity merely because a variable name ends in `Id`.

Every external identifier and locator still gets a dedicated newtype or record, such as `PaymentProviderCustomerId` or `OrderLocator`; it never becomes a bare `Text` or `Int` in the domain. When the service owns the entity, keep the external locator beside a separately minted TypeID rather than using the locator as the entity ID.

## Review Checklist

Before accepting a domain type, verify that:

1. every service-owned identity is a domain-specific TypeID-backed type;
2. every external, runtime-owned, or locator identity has an explicit nominal type and owning authority;
3. no key domain field is a raw primitive or type synonym;
4. invalid values are rejected at the constructor or parser boundary;
5. derived instances preserve domain meaning rather than expose primitive behavior;
6. generated Keiro types are reused instead of wrapped again; and
7. a persisted representation or identifier-domain change has explicit compatibility evidence and rollout ordering.

## Related Patterns

- [Keiro Service Architecture](overview.md)
- [Specification and scaffolding](spec-and-scaffolding.md)
- [Enforced identifier domains](../keiro/identifier-domains.md)
- [TypeID prefix naming](../keiro/typeid-prefix-naming.md)
- [Consumer-owned nominal bindings](../keiro/nominal-bindings.md)
- [Aggregate scalar expressions and transition ownership](../keiro/aggregate-expressions.md)
- [Brownfield Keiro adoption](../keiro/brownfield-adoption.md)
- [Integration event contracts](../messaging/integration-events.md)
