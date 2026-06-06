# Build-Time Validation of Keiki Transducers

Keiki can check, at build time, that a transducer is well-formed — before any event is ever
replayed. Wire these checks into every service's test suite so a malformed aggregate fails
CI, not production hydration. This guide covers the one umbrella call you should reach for
first, the structured warnings it returns, and the deeper solver-backed checks for when you
need exact answers.

## Start with `validateTransducer`

`validateTransducer` is the umbrella. One call runs three checks over the `HsPred` carrier,
purely (no z3 process), and returns a flat list of structured warnings:

```haskell
import Keiki.Core (validateTransducer, defaultValidationOptions)

-- The canonical assertion: a well-formed aggregate yields no warnings.
validateTransducer defaultValidationOptions incidentTransducer == []
```

Put that `== []` in an hspec/HUnit case for every aggregate and process-manager transducer.
It runs in microseconds and needs no external solver.

## The warnings it returns

Each element is a `TransducerValidationWarning s`. You can pattern-match on it — it is
structured data, not a string — and every kind names the offending edge by the typed
`EdgeRef s` locator (`EdgeRef { edgeSource :: s, edgeIndex :: Int }`), the same locator the
runtime explainer (`stepEither`) uses.

- **`HiddenInput { tvwEdge, tvwInCtor, tvwMissingSlots, tvwDetail }`** — an edge consumes
  command information its output does not emit, so the command cannot be reconstructed on
  replay. `tvwMissingSlots` names the field(s) left off the wire. Fix: add the missing
  command field to the emitted private event, or stop reading it in the guard/update.

- **`NondeterministicPair { tvwSource, tvwEdgeA, tvwEdgeB, tvwInCtor, tvwDetail }`** — two
  outgoing edges of the same vertex have guards that can both hold for one command. That is
  a single-valuedness violation; at runtime it is exactly what `stepEither` reports as
  `AmbiguousEdges`. Fix: make the guards mutually exclusive.

- **`PossiblyDeadEdge { tvwEdge, tvwDetail }`** — an edge that can never fire: its source
  vertex is unreachable from `initial`, or its guard is statically unsatisfiable (e.g. a
  literal `PBot`). "Possibly" because the structural pass is conservative. Fix: remove the
  dead edge or correct the reachability/guard.

## Tuning which checks run

`ValidationOptions` toggles each check; `defaultValidationOptions` enables the three
soundness checks and leaves the opaque-guard audit off:

```haskell
data ValidationOptions = ValidationOptions
  { failOnEpsilonReadsInput :: Bool   -- hidden-input check
  , checkDeterminism        :: Bool   -- overlapping-guard check (pure)
  , checkReachability       :: Bool   -- dead-edge check (structural)
  , warnOpaqueGuards        :: Bool   -- opt-in opaque-guard audit (default off)
  }
```

Disable a check with record-update syntax, e.g.
`defaultValidationOptions { checkDeterminism = False }`.

## The opt-in opaque-guard audit

The pure determinism and dead-edge checks treat an opaque `TApp` guard (a closure Keiki
can't read — typically a collection-content test like `Map.member`/`all`/`null` lifted
through a closure) as an unconstrained Boolean, so they silently *under-verify* such edges:
a green result that did not actually check the guard. Turn on `warnOpaqueGuards` to surface
them:

```haskell
validateTransducer defaultValidationOptions { warnOpaqueGuards = True } myTransducer
-- ⇒ [ OpaqueGuard { tvwEdge = EdgeRef {...}, tvwDetail = "guard contains an opaque TApp..." } ]
```

It is **off by default** so existing `== []` assertions don't change meaning. Use it when
auditing which guards the solver actually saw. See
[collections-and-opaque-guards.md](./collections-and-opaque-guards.md) for what to do about
each finding.

## Exact answers: the solver-backed variants

`validateTransducer`'s determinism check is *pure and conservative* — it flags only
overlaps it can prove syntactically (both-`PTop`, same-constructor), never a false positive,
but it can miss an overlap it cannot prove. When you need the exact answer, call the
z3-backed checks in `Keiki.Symbolic` directly:

```haskell
import Keiki.Symbolic (checkTransitionDeterminismSym, checkDeadEdgesSym)

checkTransitionDeterminismSym myTransducer  -- proves overlaps the pure path can't
checkDeadEdgesSym             myTransducer  -- proves a guard unsatisfiable in isolation
```

These require the `z3` SMT solver on `PATH` (the symbolic analyses fail loudly without it).
Reserve them for a dedicated, possibly slower test group; keep the pure
`validateTransducer` as the always-on fast assertion.

## Recommended test shape

```haskell
describe "Keiki well-formedness" $ do
  it "incident aggregate validates clean" $
    validateTransducer defaultValidationOptions incidentTransducer `shouldBe` []
  it "reservation aggregate validates clean" $
    validateTransducer defaultValidationOptions reservationTransducer `shouldBe` []
  it "escalation process manager validates clean" $
    validateTransducer defaultValidationOptions escalationTransducer `shouldBe` []
  -- optional, slower, needs z3:
  it "no provable determinism violations (solver)" $
    checkTransitionDeterminismSym incidentTransducer `shouldBe` []
```

See also: [transducer-best-practices.md](./transducer-best-practices.md) (the "Emit Every
Command Field Needed For Replay" rule that `HiddenInput` enforces) and
[diagnosing-rejected-commands.md](./diagnosing-rejected-commands.md) (the runtime mirror of
the determinism check).
