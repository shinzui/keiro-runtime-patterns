---
type: Standard
title: "Mapped consumer surfaces"
description: "Carrying mapped declarations through private events, snapshots, work queues, query contracts, and aggregate-sourced projections"
timestamp: 2026-09-18T05:30:00Z
generated:
  by: process:claude-code
  at: "2026-09-18T05:30:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-mapped-consumer-surfaces
tags: [keiro, mapped-consumer-surfaces]
status: current
---

# Mapped consumer surfaces

**Treat every mapped occurrence as a typed consumer with its own persisted or operational rollout consequence.**

The complete surface is stable [Language 5](language-versions.md), released in Keiro 0.12.0.0 and fixed by `mori://shinzui/keiro/masterplans/34-make-keiro-dsl-regeneration-semantically-local-and-source-stable-before-wide-adoption` and `mori://shinzui/keiro/masterplans/35-make-mapped-types-first-class-across-queues-read-models-and-projections-before-fleet-adoption`. A service still on Language 4 keeps its released meaning, but the surface below is not available to it; move the service rather than emulating the surface locally.

## Declare the complete private consumer graph

Language 5 carries mapped type expressions through these checked roots:

| Surface | Generated authority | Standing consequence |
| --- | --- | --- |
| Aggregate command or private event | Aggregate types, codec, and harness | Consumer build; incompatible event bytes need a schema bump and upcaster. |
| Aggregate register | Transducer and structural conformance | Snapshot hydration may miss and full-replay. |
| Workqueue payload field | `Queue`, `QueueCodec`, and `QueuePolicy` | Persisted queued jobs need a backward-reading decoder, a drain, or a transitional codec. |
| Read-model query input/result | Generated `QueryContract` aliases | Callers and the hand-owned query body must recompile; no SQL or table migration is inferred. |
| Aggregate-sourced inline/catalog projection | Derived handler relation and aggregate-source fingerprint | Named handlers require review; replayable catalog owners may require a fenced group rebuild. |

A nested mapped declaration inherits every checked consumer path that reaches it. Unused declarations still retain service-level structural law and ledger evidence; they do not become aggregate consumers.

## Preserve one codec authority per boundary

Use `mapped structural` only when the DSL owns the exact private JSON shape and the hand-owned binding is total both ways. Use `mapped opaque` when the consumer `ToJSON`/`FromJSON` implementation remains authoritative or shape-to-domain conversion can reject. Do not make both a generated structural codec and a consumer codec current writers for one event boundary.

Queue payloads keep the schema-version-1 envelope contract while their typed fields use the generated mapped codec plan. Query contracts are Haskell aliases only. Projection consumers derive from the authoritative aggregate event source; category and all-history sources remain heterogeneous decoder boundaries and are not inferred.

## Keep nominal leaves nominal under candidate version 6

Candidate [Language 6](language-versions.md) adds `StructuralNominalLeaves`: a declared `id`, `enum`, or `mapped nominal` scalar may appear inside structural records, unions, `Optional`/`List`/`Map` containers, typed workqueue fields, and read-model query input/results. Released services stay on Language 5 until the candidate is published; the rules below govern the candidate branch.

- **Name the declaration, not an opaque twin.** The generated private shape carries the nominal domain type, not its `KindID` or primitive. One context-owned `Structural.NominalLeaves` module applies the declared binding and Keiro-owned ID or scalar admission wherever a generated codec meets the leaf. Replace the pre-6 workaround — a `mapped opaque` twin of a consumer-bound ID, or an opaque `Maybe` wrapper — rather than keeping both.
- **Treat that replacement as a mapped type change.** `diff` reports opaque-or-`Text`-to-nominal replacement conservatively as `MappedFieldTypeChanged` at every affected root. Generate the historical codec comparison, run the old codec against committed missing/null/present samples, and require byte parity plus rejection of malformed IDs. That evidence does not waive event versioning, queue drain, or snapshot rules.
- **Enum leaves are exact.** A nominal enum leaf codec accepts and emits only the declaration's declared wire spellings; an optional enum leaf may default to one of its constructors with `on-missing`.
- **Key maps only by IDs.** `Map[DeclaredId] T` admits JSON object keys through the ID codec and generates `Map DeclaredId T`. The key must be an `id`; enums, nominal scalars, and mapped declarations are rejected. A consumer-bound key type must declare a checked law that its `Ord` agrees with canonical TypeID text ordering; generated conformance checks it over every pair of fixtures, so supply fixtures that exercise ordering.
- **Nested leaves enter the aggregate fold.** A nominal leaf inside a structural declaration that an aggregate's persisted event payload or snapshot register contains contributes a `nested-nominal-use` segment — path, name, representation (ID prefix, enum constructor-to-wire pairs, or scalar kind), and for a consumer binding its canonical type, binding, and binding version — to that aggregate's fold fingerprint. Introducing such a leaf, or changing its prefix, enum wire spelling, or binding version, moves the fingerprint and follows the [evolution gates](evolution-and-rollout.md). Declaring version 6 alone does not.
- **Read nominal findings per path.** Nominal prefix, domain, representation, binding, fixture, and canonical-type diffs name every affected structural event, snapshot, workqueue, command, and query path with its own surface context; key position is recorded separately from map values. Coverage report schema 1 appends `nominalBoundaries` and classifies nominal-only queue and query roots as structural rather than opaque.

Aggregate guards and declarative router selection may traverse required structural paths down to these leaves; see [aggregate scalar expressions](aggregate-expressions.md).

## Establish a service baseline before changing a mapping

Move the whole source or workspace to Language 5, declare the complete queue/query/catalog authority, run `check` with binding and coverage evidence, and resolve every opaque or unsupported boundary. Scaffold once, fill the new create-once obligations, compile the runtime package, and run the generated service conformance target.

Persist the new semantic-impact baseline, then run `diff` against the deployed revision. A preamble-only edit is not adoption, and a green repository qualification does not authorize a queue drain, schema migration, projection rebuild, or fleet rollout.

## Act on every reported consequence independently

- `private-event-history`: deploy a contiguous upcaster and run the real-log replay audit.
- `snapshot-hydration`: budget full replay and bump an explicit fold token for semantic changes invisible to shape.
- `workqueue-history`: deploy a backward reader before producers; otherwise stop producers and drain, or use a temporary dual-shape codec.
- `query-api`: recompile callers and the hand-owned query implementation; make application DDL decisions separately.
- `projection-handler-review`: review every named live and replay handler; no SQL change is inferred from the mapped event edit.
- `projection-rebuild`: finish or abandon incompatible active runs, deploy the matching catalog and holes, then rebuild the named group under its fence.
- `consumer-build`: rebuild the exact named consumer even when no durable history changes.

Do not clear one consequence with evidence for another. A compatible query build says nothing about queued payloads; a green projection replay says nothing about an external public contract.

## Related Patterns

- [Semantic-local Keiro DSL regeneration](dsl-semantic-locality.md)
- [Projection catalogs](projection-catalogs.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Typed PGMQ jobs](../messaging/pgmq-jobs.md)
