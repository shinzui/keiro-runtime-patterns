---
type: Guide
title: "Resolving Keiki Operator Conflicts with `lens` / `generic-lens`"
description: "Resolving the lens / generic-lens (.>) operator clash three ways"
timestamp: 2026-07-31T16:27:44-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-operator-conflicts
tags: [keiki, operator-conflicts]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T09:35:21-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; verified exported symbols, signatures, version claims, and links.
  - kind: human
    reviewer: nadeem
    reviewed_at: 2026-07-31T23:27:44Z
    document_timestamp: 2026-07-31T16:27:44-07:00
    scope: guidance
    outcome: approved
    context: >-
      Owner review of the recipe ordering: Recipe A is the fleet default because the explicit operator import reads best, and Recipe C is demoted to simple in-builder comparisons.
---

# Resolving Keiki Operator Conflicts with `lens` / `generic-lens`

**Keep transducer guards readable without letting shared-prelude operators make imports ambiguous.**

Keiki gives transducer authors infix predicate and term operators — comparison `(.<)`
`(.<=)` `(.>)` `(.>=)`, equality `(.==)` `(./=)`, logical `(.&&)` `(.||)`, and arithmetic
`(.+)` `(.-)` `(.*)`. They read well: `B.reg @"onHand" .>= lit 1`. The problem is a name
collision: a service whose shared prelude re-exports `lens`/`generic-lens` already binds
some of these names. The sharpest is `(.>)` — in `lens` it is optic composition, in Keiki it
is greater-than — so the bare `(.>)` becomes ambiguous and the module will not compile.

There are three fixes. Pick per module; they are not mutually exclusive.

## Recipe A — hide and re-import (preferred)

**Prefer Recipe A.** Hide the clashing names out of the prelude and re-import Keiki's
explicitly:

```haskell
import MyService.Prelude hiding (Index, (.>))
import Keiki.Core (lit, (.&&), (.+), (.-), (.<=), (.==), (.>), (.>=))
import qualified Keiki.Builder as B
```

The guard then reads as the arithmetic and comparison it is:

```haskell
reserveIcuBed = B.do
  B.requireGuard (B.reg @"closed" .== lit False)
  B.requireGuard (B.reg @"availableIcuBeds" .> lit 0)
  B.requireGuard (B.reg @"reservedIcuBeds" .+ d.requestedBeds .<= B.reg @"bedCapacity")
  B.requireGuard (d.requestedBeds .>= lit 1 .&& d.requestedBeds .<= lit 4)
  B.slot @"availableIcuBeds" =: (B.reg @"availableIcuBeds" .- lit 1)
  B.slot @"reservedIcuBeds" =: (B.reg @"reservedIcuBeds" .+ d.requestedBeds)
```

Keiki's fixities mirror ordinary Haskell — `.*` at 7, `.+`/`.-` at 6, comparisons at 4,
`.&&` at 3, `.||` at 2 — so `reg .+ x .<= cap` and `a .>= lit 1 .&& a .<= lit 4` group the
way they look, with no defensive parentheses. One import discipline covers guards inside a
builder block and compound `HsPred` values built outside one, so the same condition is
spelled the same way everywhere in the service.

The cost is maintenance: extend the `hiding` list each time you reach for another clashing
operator. A forgotten entry is a compile-time ambiguity error, not a silent defect, so the
failure mode is cheap.

## Recipe B — qualified `Keiki.Operators`

`Keiki.Operators` re-exports exactly the Keiki predicate/term operators (and the
`tadd`/`tsub`/`tmul` aliases) and nothing else, designed for qualified import. The bare
`(.>)` stays with `lens`; Keiki's lives under the qualifier:

```haskell
import MyService.Prelude                 -- lens (.>) etc. untouched
import Keiki.Core (lit)
import qualified Keiki.Operators as K

guard = lit threshold K..< someTerm K..&& lit 0 K..<= otherTerm
```

`K..>` is visually noisy, which is why it is not the default. It needs **zero** changes to
the unqualified import list — no `hiding` to maintain — so reach for it when a module uses
so many Keiki operators that the `hiding` list becomes the thing under review.

## Recipe C — function-style guard verbs

When the predicate is being conjoined into an edge's guard inside a `B.do` block, you do not
need the operator at all. `Keiki.Builder` exposes clash-free verbs:

```haskell
import qualified Keiki.Builder as B

edge = B.do
  B.requireGt (B.reg @"availableIcuBeds") (lit 0)   -- a > 0
  B.requireGe d.availableUnits            (lit 1)   -- >= 1
  -- also: requireLt, requireLe, requireEq, requireCmp, requireGuard
```

The verbs never clash and need no import list at all, which makes them a reasonable local
choice for a module with one or two simple comparisons. They do not compose: a condition
joining comparisons with `.&&`/`.||`, or any predicate built outside a builder block, still
needs the operators and therefore Recipe A or B. Prefer Recipe A so one module does not
spell the same condition two ways.

## Know The Boundary

No function-style aliases exist for the comparison *operators* beyond the builder verbs
above (there is intentionally no `greaterThan`/`lessOrEqual`): inside a builder the verbs
cover the simple cases, and everywhere else the operators themselves do, under Recipe A's
explicit import or Recipe B's qualifier.

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) applies these imports in the complete authoring workflow.
- [Build-Time Validation](./build-time-validation.md) shows how readable structural predicates feed the pure checker.
