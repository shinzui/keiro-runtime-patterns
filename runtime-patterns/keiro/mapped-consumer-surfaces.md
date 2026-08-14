---
type: Standard
title: "Mapped consumer surfaces"
description: "Carrying mapped declarations through private events, snapshots, work queues, query contracts, and aggregate-sourced projections"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
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
