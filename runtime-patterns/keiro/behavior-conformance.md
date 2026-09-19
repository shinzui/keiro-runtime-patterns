---
type: Assessable Standard
title: "Behavior conformance and obligations"
description: "Inventorying every live transition, rejection cell, and replay-only transition of a declared aggregate and proving each one with a typed witness"
timestamp: 2026-09-19T15:34:04Z
generated:
  by: human:nadeem
  at: "2026-09-19T15:34:04Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-behavior-conformance
tags: [keiro, behavior-conformance]
status: current
patternId: PAT-1
applicability:
  scope: >-
    Services that declare Keiro aggregates in a .keiro specification and
    scaffold the generated behavior contract for them.
  languages: [haskell]
  dependenciesAny:
    - mori://shinzui/keiro
criteria:
  - id: conformance-report-generated
    statement: >-
      Every declared aggregate's generated behavior contract runs in CI and
      produces a keiro/behavior-conformance/1 report covering all nine key sets.
    evidenceKind: report
    severity: required
  - id: conformance-gate-passes
    statement: >-
      behaviorConformancePassed holds for every declared aggregate: the report
      has no pending, missing, duplicate, stale, or failed key.
    evidenceKind: report
    severity: required
  - id: unverified-keys-kept-honest
    statement: >-
      Keys whose evidence is not proof-strength stay in the unverified set;
      conformance tooling never relabels them as verified or source-proved.
    evidenceKind: review
    severity: required
  - id: gaps-closed-by-witnesses
    statement: >-
      A missing, stale, or failed key is resolved with an executed witness or a
      reconciled spec change, never by deleting the obligation.
    evidenceKind: review
    severity: required
  - id: fail-on-unverified-deliberate
    statement: >-
      The fail-on-unverified policy is enabled only for aggregates whose guards
      are fully generated and total, never as a blanket default.
    evidenceKind: review
    severity: advisory
---

# Behavior conformance and obligations

**A declared aggregate owes one executed witness per behavior obligation; ship the generated conformance report as a CI gate, and never close a gap by deleting the obligation.**

Keiro 0.7 makes aggregate behavior coverage finite and enumerable. The spec derives the complete obligation set, the scaffolder generates a typed contract plus a create-once holes module, and the compiled report reconciles what the service actually proved. Neither half is optional: the inventory without witnesses claims nothing, and witnesses without the inventory cannot show completeness.

## Inventory the obligations from the spec

```bash
keiro-dsl behavior-obligations domain/service.keiro --format=json
keiro-dsl behavior-obligations service.keiro-workspace --format=text
```

The `keiro-dsl/behavior-obligations/1` report inventories three obligation kinds, and the set is complete rather than sampled:

- `LiveTransition` — every live transition out of a live-reachable state.
- `RequiredRejection` — every reachable state/command cell that must refuse.
- `ReplayTransition` — every replay-only transition.

Each row carries a stable `BehaviorKey`, its owning member, an `EvidenceLevel` (`GeneratedAuthoritative`, `HoleWitnessed`, or `LegacyRuntimeWitness`), and a `GuardCoverage` classification (`GuardTotal`, `GuardPartial`, `GuardUnknown`, `GuardNotApplicable`). Keys are semantic, so reordering declarations or moving an aggregate between workspace members does not churn them.

The inventory deliberately makes no claim about consumer fill status. It says what is owed, never what is done.

## Fill the create-once holes module

Scaffolding emits `Generated.<Context>.<Aggregate>.BehaviorContract` — the requirement table, the witness types, the report, and the gate — plus a create-once `<Context>.<Aggregate>.BehaviorHoles` module exporting `behaviorWitnesses`. Fill the holes; re-scaffolding never overwrites them.

```haskell
behaviorWitnesses :: [BehaviorWitness]
behaviorWitnesses =
  [ live "behavior-v1-37578058289e05a9" [] (startCommand 0) (Emits (startedEvent 0 :| [])),
    live "behavior-v1-43b8fc7fa48595dd" activeHistory (startCommand 0) (Rejects RejectNoMatchingEdge),
    live "behavior-v1-ea258e9c47d66aac" activeHistory pingCommand NoOp,
    ReplayWitness (key "behavior-v1-f0fbe3a3ba0b40e8") activeHistory [retiredEvent 0, retirementAuditedEvent 0]
  ]
```

A `LiveWitness` states a history, a command, and a `LiveExpectation` — `Emits` a non-empty event list, `Rejects` with `RejectNoOutgoingEdges` or `RejectNoMatchingEdge`, or `NoOp`. A `ReplayWitness` states a history prefix and the observed chunk. `Pending` is the honest placeholder for work not yet done; it is a scaffolding aid, and it fails the gate exactly as a missing witness does.

Witnesses execute for real. Live keys run through `stepDetailedEither` and replay keys through `applyEventsDetailedEither`, both crossing the generated codec, and Keiki 0.7 attribution checks the selected edge, the event values, the final vertex, and every register. A witness that merely type-checks proves nothing; one that executes against the wrong edge fails.

## Read every bucket of the report

`keiro/behavior-conformance/1` reports nine key sets, and each names a different defect:

| Bucket | Meaning |
|---|---|
| `required` | the derived obligation set |
| `filled` | one non-pending witness supplied |
| `pending` | an explicit `Pending` placeholder |
| `missing` | a required key with no witness |
| `duplicate` | more than one witness for one key |
| `stale` | a witness for a key the spec no longer requires |
| `failed` | a witness that executed and disagreed with the model |
| `verified` | passed with proof-strength evidence |
| `unverified` | passed, but the evidence is not proof-strength |

`stale` is the signal that a spec change dropped an obligation — reconcile it with the diff rather than deleting the witness reflexively. `failed` carries a `BehaviorFailure` with a stable code and detail; branch on the code.

From Keiro 0.11 the JSON report also carries an append-only `subject` field naming what was checked, so a CI run that reports several services can attribute a failure without inferring it from the file path. Generated harnesses additionally carry complete signatures, annotated behavior cells, named sample constants, and runtime-backed read-model facts; re-scaffold and recompile after upgrading. Behavior keys, wire data, shape hashes, fold identity, and replay semantics are unchanged.

## Gate on completeness, and opt into proof strength deliberately

`behaviorConformancePassed` fails on any `pending`, `missing`, `duplicate`, `stale`, or `failed` key. Run it in CI for every declared aggregate. That default deliberately tolerates `unverified` keys, because a key is verified only when its evidence is `GeneratedAuthoritative` and its guard coverage is `GuardTotal` or `GuardNotApplicable`.

`behaviorConformancePassedWith True` — the `--fail-on-unverified` policy — additionally requires an empty `unverified` set. Adopt it where the aggregate's guards are fully generated and total; do not adopt it as a blanket default, or teams will be pushed to relabel honest uncertainty.

`unverified` is an honest surface, not a bug to paper over. Under Keiki 0.7 a guard reading through a one-way projection is classified conservatively, so its key stays unverified until the projection declares an [exact domain](../keiki/exact-projection-domains.md). Conformance tooling must preserve that classification and never relabel it as source-proved.

## Related Patterns

- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md)
- [Keiro DSL language versions](language-versions.md)
- [Enforced identifier domains](identifier-domains.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Exact projection domains](../keiki/exact-projection-domains.md)
- [Structured replay and hydration](../keiki/structured-replay-and-hydration.md)
