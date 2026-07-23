---
type: Guide
title: "Resolving Keiki Operator Conflicts with `lens` / `generic-lens`"
description: "Resolving the lens / generic-lens (.>) operator clash three ways"
timestamp: 2026-07-22T09:35:21-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-operator-conflicts
tags: [keiki, operator-conflicts]
status: current
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

## Recipe A — hide and re-import

Hide the clashing name out of the prelude and re-import Keiki's explicitly:

```haskell
import MyService.Prelude hiding (Index, (.>))
import Keiki.Core (lit, (.>), (.>=), (.+), (.-))
```

Fine for a module that uses only a handful of Keiki operators. The cost is maintenance: you
must extend the `hiding` list every time you reach for another clashing operator, and a
forgotten one gives a confusing ambiguity error. This is the original Keiro workaround and
remains valid.

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

`K..>` is visually noisy, but it needs **zero** changes to the unqualified import list — no
`hiding` to maintain — which makes it the most robust choice when a module uses many Keiki
operators.

## Recipe C — function-style guard verbs (best inside a builder block)

When the predicate is being conjoined into an edge's guard inside a `B.do` block, you do not
need the operator at all. `Keiki.Builder` exposes clash-free verbs:

```haskell
import qualified Keiki.Builder as B

edge = B.do
  B.requireGt (B.reg @"availableIcuBeds") (lit 0)   -- a > 0
  B.requireGe d.availableUnits            (lit 1)   -- >= 1
  -- also: requireLt, requireLe, requireEq, requireCmp, requireGuard
```

**Prefer Recipe C when authoring a guard inside a builder block.** The verbs read well,
never clash, and need no import gymnastics. Reach for A or B only when you must build a
compound `HsPred` *value* with the operators (e.g. combining comparisons with `.&&`/`.||`
before handing the result to `requireGuard`), or when constructing a predicate outside any
builder block — in which case the qualified import (Recipe B) is cleanest.

## Know The Boundary

No function-style aliases exist for the comparison *operators* beyond the builder verbs
above (there is intentionally no `greaterThan`/`lessOrEqual`): inside a builder the verbs
cover it, and outside one the qualified `Keiki.Operators` import does.

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) applies these imports in the complete authoring workflow.
- [Build-Time Validation](./build-time-validation.md) shows how readable structural predicates feed the pure checker.
