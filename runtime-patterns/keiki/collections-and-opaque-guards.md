---
type: Pattern
title: "Collections and Opaque Guards"
description: "Modeling collections without losing solver verification through opaque guards"
timestamp: 2026-07-22T09:35:21-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-collections-and-opaque-guards
tags: [keiki, collections-and-opaque-guards]
status: current
---

# Collections and Opaque Guards

**Store collections when needed, but keep every durable invariant structurally visible to Keiki.**

Keiki has no first-class collection registers. This is the single most common thing Keiro
service authors trip over, so read this before modeling any aggregate whose state holds a
`Map`, `Set`, or list. The short version from Keiki's own
`docs/guide/modeling-collections.md`: project the collection down to the scalar facts your
guards actually need, and promote any element with its own identity and lifecycle into its
own aggregate. **Storing** a collection is fine and fully verified; **guarding on its
contents** through a closure silently loses Keiki's verification; and the structural
collection feature is **deferred**, not coming soon.

## Why there is no collection vocabulary (and what was decided)

A keyed-collection feature (structural `UInsert`/`UDelete`/`UAdjust` updates, `PMember`/
`PAll` guards, `TLookupField` element reads) was specified, prototyped, and reviewed in
2026-06. The review reached a deliberate **NO-GO**: the committed consumer was not actually
blocked, the real hazard was a discoverability problem (below), and shipping the irreversible
core-AST surface speculatively risked entrenching a boundary anti-pattern. The full design
and prototype are preserved in the Keiki repo
(`docs/research/collection-registers-design.md`,
`docs/plans/60-first-class-collection-registers-design-gated.md`) and may be revived if a
real keyed-collection consumer appears. Until then, use the patterns below.

## Storing a whole collection is fine — it is not opaque

The common pattern — a command carries a precomputed list and the aggregate stores it
wholesale — is **structural and fully replay-safe**:

```haskell
B.onCmd inCtorReportActiveResources $ \d -> B.do
  B.slot @"activeResourceIds" =: d.activeResourceIds   -- structural input read
  B.emit wireActiveResourcesReported ActiveResourcesReportedTermFields
    { incidentId        = d.incidentId
    , activeResourceIds = d.activeResourceIds          -- carry it for replay
    }
  B.goto Active
```

Because the list arrives on the command, `=:` is a structural read: `solveOutput` inverts
it and `validateTransducer` sees the whole list on the wire. Nothing is degraded. The
aggregate is simply trusting the caller to have computed the list correctly, so keep the
append/remove/membership invariants in the application layer (against the read model) and
test duplicate/remove/idempotent-retry behavior there.

A whole-list **guard** is also fine when it is structural — emptiness is the typical one:

```haskell
B.requireGuard (B.reg @"activeResourceIds" .== lit [])   -- structural PEq; verified
```

## The footgun: opaque collection *guards*

The degradation happens only when you branch on collection *contents* through an opaque
closure, because Keiki's predicate language has no node for membership/quantification:

```haskell
-- DON'T rely on this being verified:
B.requireGuard (TApp1 (k `elem`) (B.reg @"activeResourceIds") .== lit True)
B.requireGuard (TApp1 (all isResolved) (B.reg @"blockers")    .== lit True)
```

These compile and *evaluate* correctly at runtime. But `Keiki.Symbolic.translateTermSym`
turns the closure into an unconstrained free SBV variable, so the single-valuedness and
dead-edge analyses **cannot see through the guard** and silently under-verify the edge. You
get a green build that did not check what you think it did.

## Audit for them with `warnOpaqueGuards`

The opaque-guard check is opt-in (it is off in `defaultValidationOptions` so it never
changes an existing `== []` assertion). Turn it on to find every guard the solver could not
see:

```haskell
import Keiki.Core (validateTransducer, defaultValidationOptions)

opaqueGuards =
  [ w | w@OpaqueGuard{} <- validateTransducer
          defaultValidationOptions { warnOpaqueGuards = True } myTransducer ]
```

Each `OpaqueGuard` names the edge by `EdgeRef`. Consider asserting your aggregates have
*no unaudited* opaque guards, or at least reviewing each one. This call still runs all seven
default checks; the list comprehension deliberately filters the combined result so this audit
contains only `OpaqueGuard` findings.

## The sound options when you need an in-aggregate collection invariant

If a collection invariant must be enforced *inside* the aggregate (not just in the
application layer), the options today are:

1. **Scalar tallies and application-layer invariants (default).** Keep append/remove/
   membership in the code that builds the command, and let the aggregate store scalar facts
   such as `openBlockerCount`, `pendingTransferNeeds`, or an emptiness flag. A whole-list
   command field is sound when it is emitted for replay, but treat it as a read-model-style
   summary, not the source of in-aggregate membership or quantifier guards.

2. **Sub-entity-as-aggregate split.** If a collection element has its own identity and
   lifecycle (a blocker that opens/escalates/resolves), model *each element* as its own
   small **scalar** aggregate on its own stream, coordinated by a keiro process manager. Full
   Keiki guarantees per sub-aggregate. This is usually the better design when you reach for
   a collection register — it is often a sign the aggregate boundary is too coarse.

3. **Counts and flags instead of structure.** Many "all resolved?" guards can be replaced by
   maintaining a scalar counter slot (`openBlockerCount`) updated structurally with
   `.+`/`.-`, and guarding `B.reg @"openBlockerCount" .== lit 0`. Fully verified, no closure.

## Quick reference

| You want to… | Do this | Verified? |
|---|---|---|
| Store a list from the command | `B.slot @"xs" =: d.xs` | ✅ |
| Guard "list is empty" | `B.reg @"xs" .== lit []` | ✅ |
| Guard "k is a member" | application layer, or a count/flag slot | ✅ |
| Guard "k is a member" via `Map.member` in a `TApp` | works at runtime, but **not** symbolically verified — audit with `warnOpaqueGuards` | ⚠️ |
| Per-element lifecycle inside the aggregate | split the element into its own scalar aggregate | ✅ |

## Related Patterns

- [Build-Time Validation](./build-time-validation.md) explains the seven defaults and the opt-in audit.
- [Keiki Transducer Best Practices](./transducer-best-practices.md) covers whole-collection command fields and replay.
- [Checked Composition](./checked-composition.md) explains when independent identities belong on separate streams rather than inside one machine.
