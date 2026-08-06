---
type: Guide
title: "Brownfield Keiro Adoption"
description: "Adopting Keiro around existing domain types, stored JSON, and independent same-context scaffolds with workspace migration, codec evidence, and replay-safe cutover gates"
timestamp: 2026-07-29T19:40:01Z
generated:
  by: human:nadeem
  at: "2026-07-29T19:40:01Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-brownfield-adoption
tags: [keiro, brownfield-adoption]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T19:40:01Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Brownfield Keiro Adoption

**Keep the domain types and historical bytes; replace implicit contracts with one checked structural schema, total bindings, and staged evidence.**

Keiro's structural consumer mappings let an existing service adopt the checked DSL without rewriting its Haskell domain model into generated types. The same path benefits new services whose domain types should remain hand-owned: the `.keiro` declaration owns the private-event wire schema, a total binding connects that schema to the application type, and generated field witnesses expose selected decision scalars to Keiki.

## Choose Structural Or Opaque Honestly

Use `mapped structural` when the complete private-event JSON shape can be declared and every generated shape value converts totally to and from the consumer type. The checked declaration owns keys, tags, required/optional/null behavior, defaults, unknown-field policy, canonical identity, and binding version. `StructuralBinding domain shape` owns only construction and destruction.

Use `mapped opaque` when an external or consumer codec must remain authoritative, when conversion from a valid declared shape can fail, or when a nested contract cannot be described honestly. Keiro delegates JSON only at that named boundary and makes no structural claim beneath it. Fixtures, goldens, or a historical comparison do not turn an opaque mapping into a structural one.

Never keep two live codec authorities. After cutover, the generated structural codec alone writes current private events. A historical codec may survive in migration tests or an explicit old-version upcaster rung, never as a current-version fallback.

## Start From Stored Bytes

Before writing the mapping, inventory every durable surface: private events and versions, snapshots, imported rows, queued jobs, timers, workflow values, and public messages. Record each writer, reader, retention period, and actual serialized form.

Capture sanitized production examples before deriving the declaration. Include every observed union tag, absent and explicit-null optionals, old bug-era payloads, and the oldest supported version. Constructor names and today's `ToJSON` instance are evidence, not the contract; Aeson options and old releases may have written something different.

Public contracts and queue payloads keep their separately owned DSL grammars. Structural mapped coverage currently applies to private aggregate payloads and mapped registers. Snapshot payloads remain a consumer-JSON cache boundary; mapping fingerprints invalidate incompatible seeds, but the generated event codec is not the snapshot codec.

## Choose one file or a service workspace

Keep a small service in one `domain/service.keiro` file. When complete aggregates already live in separate same-context files, preserve those review boundaries with one versioned `.keiro-workspace` manifest instead of combining the sources or continuing to scaffold them independently.

The manifest owns the stable service identity, module/layout policy, and member set. Every aggregate stays whole in one member, while every shared id, enum, rule, or mapped declaration moves to exactly one owning member. Run `check`, `scaffold`, and `diff` against the manifest so validation, context-level modules, scaffold history, coverage, compatibility, and replay impact describe the whole service.

To adopt one existing multi-aggregate file, first list it as the manifest's only member. Split aggregates later as source-ownership moves. To adopt output from several independent same-context scaffolds, keep the output tree and scaffold the workspace once:

```bash
keiro-dsl scaffold domain/service.keiro-workspace --out service-core/src
```

With no workspace record present, the first run imports only attributable generated files: paths in the surviving legacy context record have `record` evidence, while orphaned planned Generated paths require the exact generated banner for `banner` evidence. It writes a workspace migration report, marks the legacy record `superseded-by:` without invalidating old readers, and leaves holes, unrelated files, and likely-stale paths unclaimed. It never deletes or renames. Any bannerless file at a planned Generated path refuses the entire run before bytes change.

## Declare One Schema Authority

A structural declaration names the consumer type, hand-owned binding and fixtures, stable identities, optional register initial, and complete wire policy:

```text
mapped structural record ArtifactInfo {
  haskell package=my-service module=MyService.Domain type=ArtifactInfo
  binding = "MyService.Artifact.Bindings.artifactInfoBinding"
  binding-version = "1"
  canonical-type = "my-service.ArtifactInfo.v1"
  fixtures = "MyService.Artifact.Bindings.artifactInfoCases"
  initial = "MyService.Artifact.Bindings.emptyArtifactInfo"
  wire object constructor=ArtifactInfo unknown-fields=reject {
    artifactKey  as "artifact_key"  : Text          required
    artifactHash as "artifact_hash" : Optional Text optional on-missing=null
    active       as "active"        : Bool          optional on-missing=false
  }
}
```

Structural records, string enums, and tagged unions may contain supported scalars, optionals, lists, text-keyed maps, nested mapped types, and explicit `Json` leaves. The checker rejects recursion, ambiguous or non-injective shapes, ill-typed defaults, missing identities, and mapped registers with no declared initial value.

Before writing files, inspect every obligation:

```bash
keiro-dsl check domain/service.keiro --explain-bindings \
  --coverage-report build/keiro-coverage.json
```

The report groups binding, fixture, and initial symbols by consumer package and module and names every command, event, and register use site. Coverage inventories named structural, opaque, explicit-`Json`, snapshot, and unsupported boundaries; it deliberately does not manufacture one percentage. Add `--fail-on-opaque` only when the named-root policy is an intentional project gate.

## Scaffold And Fill Total Bindings

The first scaffold emits private generated shape modules, the aggregate codec, a `StructuralProjections` facade, and create-once binding/fixture/initial skeletons in the modules named by the declarations:

```bash
keiro-dsl scaffold domain/service.keiro --out service-core/src
```

Fill every binding direction and deterministic `FixtureCases` value. Do not repeat wire keys, tags, defaults, or null policy in the Haskell binding. Re-scaffolding skips the hand-owned file and reports newly required field, constructor, fixture, or initial holes from the persisted scaffold record.

Use `genericStructuralBinding` only when consumer and generated representations have exactly the same constructor names and order, selectors and order, arity, and field types. It derives no JSON policy and deliberately performs no coercion, prefix stripping, or positional guess. Any mismatch must use the explicit skeleton.

## Model The Transducer Around Whole Values

Keep consumer values whole in commands, registers, and events. Use generated Keiki 0.4 field witnesses only for eligible scalar decisions in guards. For readability, this example aliases the generated identifier locally as `artifactKeyWitness`:

```haskell
B.requireEq
  (inpProj artifactKeyWitness
    inCtorObserveArtifact #artifact)
  (regProj artifactKeyWitness #currentArtifact)
B.slot @"currentArtifact" =: d.artifact
B.emit wireArtifactRecorded ArtifactRecordedTermFields
  { artifact = d.artifact }
```

Use the actual deterministic name inserted by the scaffolded hole. Projections are direct-base and guard-only. Updates and outputs copy whole values through the ordinary replay-invertible path. Prefer explicit scalar registers for central lifecycle facts; use projections for a small number of observations that would otherwise force domain-model duplication or opaque `TApp1` guards.

Every command field consumed by a guard or update must still be recoverable from the head event. Structural mapping does not relax replay, determinism, or `ValidatedEventStream` rules. See [Typed Field Projections](../keiki/typed-field-projections.md) and [Keiki Transducer Best Practices](../keiki/transducer-best-practices.md).

## Require Generated And Historical Evidence

The generated harness must pass after the holes are filled. It checks the executable transducer, current event round trips, historical upcaster goldens, both binding laws, declared missing/default/null/unknown-field policy, enum/union/optional fixture coverage, generated projection-witness agreement, and forward-versus-replay equality over the final vertex and every register.

For a brownfield structural type, scaffold a non-production comparison runner after the historical corpus exists:

```bash
keiro-dsl scaffold domain/service.keiro --out service-core/test-migration \
  --codec-comparison ArtifactInfo \
  --comparison-out service-core/test-migration/Generated/MyService/Structural/CodecCompare/ArtifactInfo.hs
```

Compile it beside an explicit `HistoricalCodec ArtifactInfo`. Require RFC 8785-canonical JSON parity, matching decode outcomes, and complete historical/typed branch coverage. Every difference is either a corrected transcription of the existing contract or an explicit new schema version and upcaster. There is no "close enough" category.

Comparison is finite evidence. It does not prove that every historical value was sampled, that an event still selects one inverting edge, or that replay folds to the same state.

## Gate The Cutover

Run the complete migration ladder before traffic switches:

1. Compile the consumer bindings and generated code.
2. Run `keiro-dsl check`, the coverage inventory, and `diff --since REF --explain` against the service file or workspace manifest.
3. Pass the generated harness, genuine historical goldens, and structural codec comparison.
4. Construct every `ValidatedEventStream`; never substitute `mkEventStreamUnchecked`.
5. Run one `AuditFull` against a production copy for the first cutover. A non-zero `auditExitCode` blocks deployment.
6. Use a stop-the-world or blue/green switch with exclusive ownership of each stream category; after the first new-version append, rollback is roll-forward-only.

For later changes, use the diff's replay-impact file and `AuditTargeted`. Run `diff --coverage-report ... --fail-on-opaque-increase` only when the service has chosen that operator policy. A binding symbol or version change is not inspectable from spec text, so the differ points to binding laws, fixtures, historical comparison, and replay evidence instead of claiming compatibility.

## Related Patterns

- [Keiro-dsl Adoption](dsl-adoption.md)
- [Evolution Gates and Rollout Ordering](evolution-and-rollout.md)
- [Runtime Assembly](runtime-assembly.md)
- [Typed Field Projections](../keiki/typed-field-projections.md)
- [Specification and Scaffolding](../architecture/spec-and-scaffolding.md)
- [Test Layout](../architecture/test-layout.md)
- [Composable service workspaces](service-workspaces.md)
