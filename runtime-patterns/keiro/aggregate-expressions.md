---
type: Standard
title: "Aggregate scalar expressions and transition ownership"
description: "Declaring typed guards and writes that generate the Keiki transducer, and marking the transitions that stay hand-owned"
timestamp: 2026-08-05T19:47:25-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-aggregate-expressions
tags: [keiro, aggregate-expressions]
status: current
---

# Aggregate scalar expressions and transition ownership

**From [language version 2](language-versions.md) onward every aggregate transition is either fully generated from its declared guard and writes or explicitly `implementation hole` — never both.**

Version 2 introduced this contract and every later version keeps it: declared guards and writes are compiled into the generated Keiki transducer instead of being restated by hand. That moves the generated/hand-owned firewall, so decide who owns each transition deliberately. Author new sources at the [stable version](language-versions.md); the examples here use it.

## Use the six direct scalar types

Aggregate commands, events, and registers share one checked type model. The direct scalars are `Text`, `Int`, `Integer`, `Bool`, `Time`, and `Natural`. `UTCTime` is an accepted source spelling; canonical output is `Time`.

| Capability | Types |
|---|---|
| Equality in a guard | all six, plus bound nominal scalars |
| Ordering in a guard | `Int`, `Integer`, `Time`, `Natural`, plus bound nominal `Int`/`Natural`/`Time` |
| Arithmetic | `Integer` (exact) and `Natural` (total) only |

`Text` and `Bool` ordering is rejected. `Int` arithmetic is rejected because the symbolic domain does not model machine-width overflow — use `Integer` when a value is computed, and keep `Int` for literals, comparison, and whole-value writes. Division, remainder, mixed numeric operands, implicit coercion, and `Time` arithmetic are all rejected by `check`.

`Natural` subtraction is **total monus**: `a - b` is `max 0 (a - b)`, so `2 - 5` is `0`. It cannot fail, which means the guard — not the carrier — must reject an over-decrement. The same rule governs the underlying Keiki term; see [Keiki transducer best practices](../keiki/transducer-best-practices.md).

Direct `Json`, `Optional`, `List`, and `Map` aggregate fields do not exist. Express those wire shapes through a `mapped structural` declaration.

## Write guards and writes against explicit roots

```text
language keiro-dsl 4
context accounting

aggregate Account
  regs
    balance Integer = 0
    reserved Natural = 0
    capacity Natural = 5
    openedAt Time = "2026-01-02T03:04:05.123456789012Z"
  states Open Adjusted!
  command Adjust { amount:Integer requested:Natural observedAt:Time }
  event AccountAdjusted = fields(Adjust)
  Open -- Adjust -->
    guard cmd.amount + reg.balance >= -100
      && reg.reserved + cmd.requested <= reg.capacity
      && cmd.observedAt >= reg.openedAt
    write balance := reg.balance + cmd.amount * 2
    emit AccountAdjusted
    goto Adjusted
  wire kind=ctorName fields=camelCase schemaVersion=1
```

Prefer the qualified `reg.` and `cmd.` roots everywhere. A bare name resolves only when exactly one active command field or register matches it; when both do, `check` reports `AggregateExpressionRootAmbiguous` and you must qualify. Dotted paths may cross **required** `mapped structural record` fields and must end at a supported scalar leaf; optional, union, collection, `Json`, and opaque boundaries fail before scaffolding.

Quoted literals resolve contextually as `Text` or ISO-8601 UTC `Time`; integral literals as `Int`, `Integer`, or `Natural`; Bool literals are `true` and `false`. Multiplication binds above addition and subtraction, which bind above a non-associative comparison; comparisons bind above `&&`, and `&&` binds above `||`. A predicate cannot be written to a `Bool` register — Keiki predicates and Bool terms are distinct.

Register initials are checked once, at their declared type: a `Time` initial is a quoted ISO-8601 UTC timestamp that keeps picosecond precision through event JSON, snapshots, forward execution, and replay; a `Natural` initial must be a non-negative integral literal, and its codec rejects negative or fractional values.

Every rejection is a stable code. Type failures use the `AggregateType*` family; expression failures use `AggregateExpression*` for roots, paths, literals, operands, operators, Boolean contexts, and write targets; reserved collection spellings fail as `CollectionExpressionUnsupported`. All of them come from `check`, before scaffolding writes a byte.

## Separate the three field namespaces when they must differ

A direct field carries three identities: its spec name, its generated Haskell record selector, and its wire key. By default all three derive from the spec name. From [language version 4](language-versions.md) a direct aggregate or integration-contract field can declare the other two independently:

```text
family: text
type haskell payloadType: text
region haskell serviceRegion as "region_code": text
```

- `haskell <selector>` sets the generated record selector. Use it when the natural spec name collides with something Haskell cannot express as a selector.
- `as "<wire-key>"` sets the persisted and published key. Use it when the wire is already fixed by an external contract.

Records use selectors; codecs and goldens use wire keys; a `fields(Command)` event copies the resolved three-namespace identity rather than re-deriving it. Declare an alias only when the namespaces genuinely differ — three names for one field is a cost every reader pays.

Version 4 also narrowed the generated occurrence reserved set to the 23 words GHC actually rejects, so previously refused contextual identifiers such as `family`, `via`, and `qualified` now check and compile without an alias. Remove aliases that existed only to dodge them.

Three diagnostics guard the feature: `FieldWireKeyCollision` when two fields resolve to one wire key, `FieldWireKeyInvalid` when a key is not usable, and `EvtFieldWireKeyChanged` from `diff` when a key moves between revisions. The first two are refusals. The third is a wire change even though no Haskell changed — treat it as one; see [evolution gates and rollout ordering](evolution-and-rollout.md).

## Let generation own the transition by default

For each such aggregate the scaffolder emits two generated modules:

- `Generated.<Context>.<Aggregate>.Expressions` — one typed Keiki predicate per declared guard and one typed Keiki term per register write;
- `Generated.<Context>.<Aggregate>.Transducer` — the assembled transducer, the aggregate fold fingerprint, `BehaviorOwnership (GeneratedOwned | HoleOwned)`, and an aggregate-specific `<aggregate>PredicateVerifications` action.

Generated ownership is the default and it is exclusive: no hand-owned module may replace a generated guard or write.

Explicit event fields remain hand-owned, but from Keiro 0.7 a `fields(Command)` event value is generated directly from a checked total identity mapping. Direct, aliased-wire, optional, nominal, `Time`, `Natural`, and structural fields no longer pass through a create-once identity-copy hook. An identity function left over from an earlier scaffold is reported as obsolete and cannot affect runtime execution — delete it rather than maintaining it.

## Emit an event for every state change

A transition that emits no event may no longer change control state or write registers. `check` rejects it with `AggregateEventlessStateChange`; an empty accepted edge is legal only as a true no-op. The companion code `EventOutputCommandMismatch` rejects an event output that disagrees with the command it claims to carry.

Both are append-only `DiagnosticCode` constructors, so an exhaustive match over the code set must be extended. The rule they enforce is the same durability invariant Keiki's `StateChangingEpsilon` warning protects: a change with no event leaves nothing for replay to reproduce.

## Mark a hand-owned transition explicitly

Use `implementation hole` when a predicate or update cannot be expressed in the scalar language:

```text
Reviewed -- Close -->
  implementation hole
  emit ClosedEvent
  goto Closed
```

That transition may not also carry `guard` or `write` clauses; mixing them is a definition error. Its create-once Holes module supplies exactly one stable transition function and one `FoldVersion` token. Generated code still owns the structural envelope — command matching, live/replay mode, event kinds, and target state — so do not construct a replacement transducer in the Holes module.

**Bump the transition's `FoldVersion` whenever its predicate or update behavior changes.** The aggregate fold fingerprint incorporates the token, so a bump invalidates stale snapshots. Changing hole behavior without bumping is a contract violation that the toolchain cannot see: the fingerprint stays equal and old snapshots keep being trusted.

## Run the verification action in conformance CI

`<aggregate>PredicateVerifications` returns, per transition, its label, its `BehaviorOwnership`, and the conservative `PredicateVerification` result from Keiki. Assert on it in the generated conformance suite.

Read the result honestly: an opaque hole predicate is reported `UnverifiedOpaque`, which is the correct answer, not a failure to fix by weakening the assertion. Assert that generated-owned transitions verify and that the hole-owned set is exactly the set you intended to hand-own. See [build-time validation](../keiki/build-time-validation.md) for the verification taxonomy.

From Keiro 0.7 the set of transitions reported `UnverifiedOpaque` is **larger**, because Keiki 0.7 classifies a predicate that crosses a one-way generated projection conservatively. A guard that reported `Verified*` under Keiro 0.6 can report `UnverifiedOpaque` now with no change to the spec. Runtime stepping and replay are unchanged. Restore proof strength by giving the projection an [exact domain](../keiki/exact-projection-domains.md) with its reverse witness — never by relabelling the result.

Predicate verification covers guards. For coverage of the transitions themselves — every live transition, every reachable rejection, every replay-only edge — use the generated [behavior-conformance](behavior-conformance.md) report.

## Migrate off version 1 by hand

Version-1 generated output is frozen, and version-1 whole-transducer holes are unchanged. The scaffolder never overwrites or claims to translate consumer behavior, so moving an aggregate off version 1 means rewriting its guards and writes in the spec and deleting the hand-owned logic they replace. Do it one aggregate at a time, and prove each with the replay audit before deleting the code it supersedes.

## Related Patterns

- [Keiro DSL language versions](language-versions.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Keiro-dsl adoption](dsl-adoption.md)
- [Specification and scaffolding](../architecture/spec-and-scaffolding.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Keiki transducer best practices](../keiki/transducer-best-practices.md)
- [Build-time validation](../keiki/build-time-validation.md)
