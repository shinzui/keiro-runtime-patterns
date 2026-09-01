---
type: Guide
title: "Keiro-dsl adoption"
description: "When to adopt keiro-dsl, including workspaces, mapped consumer surfaces, semantic-local regeneration, the generated-code firewall, conformance, and evolution gates"
timestamp: 2026-09-01T15:35:02Z
generated:
  by: human:nadeem
  at: "2026-09-01T15:35:02Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-dsl-adoption
tags: [keiro, dsl-adoption]
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

# Keiro-dsl adoption

**Adopt keiro-dsl for persisted contracts and evolution safety, including services that keep existing consumer-owned domain types.**

This guide decides when a service should own a checked Keiro DSL contract and where generated structure stops and hand-written domain logic begins. The default source shape is one composed `.keiro-workspace`; a bare `.keiro` input is reserved for a trivial domain with exactly one aggregate.

## Apply the adoption rule

Adopt keiro-dsl when a service has more than one node family, any integration surface such as intake, emit, or queues, expected schema/workflow evolution, existing private-event history, or a consumer-owned value whose wire shape and decision fields must be checked. The checker, generated conformance harness, and evolution gate are the payoff, and their value grows with every durable contract edge.

A trivial single-aggregate service may hand-write against the public API only when it has no queues, integration contracts, mapped persisted values, existing history, or expected evolution. Revisit that choice as soon as any of those appear. Structural mappings make retrofit adoption possible without replacing the service's Haskell domain types with generated equivalents.

When a service does adopt the DSL, create its versioned workspace immediately. Keep each aggregate whole in a readable, single-owner member and give shared declarations an explicit owner. Do not defer the workspace merely because the first delivery has one aggregate: a non-trivial single-aggregate contract still benefits from stable workspace identity and can accept another aggregate without reorganizing the original source. See [composable service workspaces](service-workspaces.md).

Keiro-dsl is a build-time parser, checker, scaffolder, harness emitter, and evolution differ—not a runtime interpreter. The `keiro-dsl` library has no dependency on `keiro`; generated and conformance code use the same public runtime APIs as hand-written services.

## Let the checker own cross-node contracts

The rule is one sentence: put mechanically checkable identity, policy, and evolution relationships in the specification instead of reconstructing them in modules or prose.

The released grammar covers aggregates and upcasters, projections and snapshots, process managers and timers, routers, integration contracts, inbox/outbox nodes, publishers, PGMQ work queues and dispatch, read models, and durable workflows. [Language 5](language-versions.md) additionally declares typed projection catalogs and revisions, versioned external-read contracts, typed domain command outcomes, and mapped workqueue/query/projection consumer surfaces. The checker verifies, among other contracts:

- complete intake and work-queue disposition tables, including dangerous retry/ack inversions;
- FIFO group-key requirements and captured opaque derivations;
- snapshot codec identity, live shape hashes, status-map totality, and contiguous upcasters;
- duplicate and incomplete aggregate upcaster chains, and the mutually exclusive `retiring event` marker;
- event retirement discipline: a deprecated event with no replay-only emitter, and a replay-only transition that emits nothing or has no live sibling;
- structural and opaque consumer mappings: total resolved type graphs, canonical and binding identities, injective wire policy, register initials, complete consumer obligations, and the exact queue/query/projection roots that consume them;
- projection catalogs: single target ownership, resolved query/group/source identities, acyclic target dependencies, handler ordering, and replay policy compatible with reset policy;
- workflow signal/await matching, unique labels, and terminal `continueAsNew`;
- resolved cross-node references and rejection handling that never marks `CommandAmbiguous` benign.

Given the same tool version, service input, and placement options, scaffolding is deterministic; committed conformance modules pin generated output byte-for-byte. A workspace composes complete same-context members before validation, so cross-member references and conflicts are checked as one service rather than by unrelated invocations.

## Keep domain decisions behind the firewall

The rule is absolute: **never edit a generated module**. Change the specification and scaffold again, or implement the hand-owned hole.

Generated modules carry `-- @generated` and are overwritten on every scaffold. `HoleStub` modules are create-once and skipped thereafter. The `FirewallSurface` checked by `firewallBreaches` prevents generated modules from containing keiki decision operators and builders such as `.==`, `./=`, `.||`, `lit`, or the `B` builder qualifier.

That firewall has exactly one exemption: the version-2 generated `Expressions` and `Transducer` modules, which are the intended generated authority for declared scalar guards and writes. Under language version 2 the spec, not a hand-written module, owns scalar decide logic for a generated transition; behavior the scalar language cannot express is marked `implementation hole` and stays hand-owned. Under version 1 every aggregate decide body remains hand-owned as before. See [aggregate scalar expressions and transition ownership](aggregate-expressions.md).

The default layout is `Generated.<Context>.<Node>` with holes under the domain namespace. `--collocate` instead places generated code at `<Context>.<Node>.Generated` beside the hand-owned layer. Structural mappings additionally emit private `Structural.Shape.*` modules, one `StructuralProjections` facade, one service-wide `StructuralConformance`, and one source-only `BehaviorSourceMap`. Binding, fixture, optional register-initial, and behavior-witness modules are create-once, hand-owned files at the qualified modules named by the declarations.

Aggregate harnesses carry only declarations in their checked semantic closure. `StructuralConformance` carries declaration-wide laws once for the service, including unused declarations. `BehaviorSourceMap` is the only generated authority for current file/line/column locations; moving source must not change stable behavior keys or aggregate contracts. Adopt that layout through [semantic-local regeneration](dsl-semantic-locality.md), not by moving assertions between generated files.

Scaffolding reports stale paths but never deletes them; review stale generated and hand-owned files separately. It also reports newly required structural binding fields, constructors, fixtures, and initials without parsing or rewriting filled Haskell bodies.

## Recognize Runtime Holes And Mapping Obligations

The established runtime surface has eight hole kinds:

1. Deterministic identifier or string derivation; opaque strategies carry a captured fixture, never only a prose rule.
2. Failure-to-action disposition, including ack, bounded retry, and dead-letter choices.
3. Explicit value-to-value mapping rather than an assumed identity conversion.
4. Envelope-field layering, cross-check, and deduplication policy.
5. Define-once stable names and contracts that generated modules reference rather than retype.
6. Body decode strictness and schema-version policy.
7. Emit optionality, made total with an explicit `_ => skip` catch-all.
8. Deployment configuration such as Kafka brokers, `groupId`, `offsetReset`, metrics, shards, and runtime tuning.

Structural mappings add a different kind of hand-owned obligation: a total `StructuralBinding`, deterministic `FixtureCases`, and a register initial when the mapped type is stored. These are not a ninth runtime escape hatch. They are the typed boundary between consumer-owned domain values and the generated private wire shape, and the generated harness tests both directions.

## Use only named escape hatches

Use `ResolveHole` when a router needs a typed hand-owned resolver instead of a read model. Keep opaque queue group-key derivation hand-owned and capture its fixture in the spec. Implement PGMQ dispatch fan-out and its raw-SQL dedup predicate in typed holes. Leave deployment configuration in hole kind 8.

`--force-generated-overwrite` is a repair footgun: it bypasses only the safety refusal for an existing generated path that lacks the banner. It can clobber a hand-edited file and is permitted only after confirming that file is disposable.

## Map Consumer-Owned Values Without A Parallel Domain Model

Use `mapped structural` when the checked declaration can own the complete private-event JSON shape and conversion between the generated shape and application type is total in both directions. The declaration owns wire keys, tags, presence, nullability, defaults, unknown-field policy, canonical type identity, and binding version. The Haskell `StructuralBinding` owns construction and destruction only.

Use `mapped opaque` when the consumer codec must remain authoritative or conversion can reject a valid declared shape. Opaque fixtures document and test the boundary but do not expose nested compatibility or scalar field witnesses.

Use `mapped nominal`, a bound `id`, or a bound `enum` when the consumer type is a total isomorphism over a single scalar, ID, or closed enumeration — the binding then keeps the application type in direct command, event, and register fields. It requires language version 2 and carries its own obligations; see [consumer-owned nominal bindings](nominal-bindings.md). Every generated service-level ID and enum has one owner module, `Generated.<Context>.Nominals`; import constructors from there rather than from an aggregate `Domain`.

Generated `StructuralProjections` witnesses let a hand-owned Keiki transducer use `regProj` and `inpProj` for eligible scalar guards while commands, registers, and events retain the consumer type. Projections are direct-base and guard-only; they do not lower nested `.keiro` paths into the transducer. Under language version 2 the generated expression modules use the same witnesses for checked dotted paths. See [Brownfield Keiro Adoption](brownfield-adoption.md) for the end-to-end choice and migration sequence.

Language 5 extends the same mapped type graph to persisted workqueue fields, paired read-model query input/results, and projections derived from an aggregate event source. Those surfaces have different rollout consequences; follow [mapped consumer surfaces](mapped-consumer-surfaces.md) and never use a green aggregate harness as evidence that an old queued payload or query caller is compatible.

## Use the complete CLI loop

Run these commands from the Git repository containing the specification:

```sh
keiro-dsl new KIND
keiro-dsl parse INPUT
keiro-dsl pretty INPUT
keiro-dsl inspect INPUT --format=json
keiro-dsl behavior-obligations INPUT --format=text|json
keiro-dsl check INPUT [--emit] [--explain-bindings] \
  [--coverage-report FILE] [--fail-on-opaque] \
  [--min-language N] [--deny-warnings] [--deny CODE[,CODE...]] \
  [--report-out FILE]
keiro-dsl scaffold INPUT --out DIR \
  [--module-root PREFIX] [--collocate] [--force-generated-overwrite] \
  [--goldens DIR] [--runtime-package PACKAGE] [--apply-name-migrations] \
  [--codec-comparison TYPE --comparison-out FILE]
keiro-dsl diff INPUT --since GIT-REF \
  [--emit-goldens DIR] [--replay-impact-out FILE] [--explain] \
  [--report-out FILE] [--gate SURFACE] \
  [--coverage-report FILE] [--fail-on-opaque-increase]
```

- `new` prints a skeleton for aggregate, process, router, contract, intake, emit, publisher, workqueue, dispatch, workflow, or operation.
- `INPUT` is normally a `.keiro-workspace` manifest, and all file-taking commands operate on that composed service. Use one bare `.keiro` file only for the trivial single-aggregate exception.
- `parse` parses and pretty-prints the normalized service specification; `pretty` is the explicit alias for that canonical render. Neither one rewrites a source's language declaration.
- `inspect --format=json` reports whether each source declared a language version and which version is effective, for a file or for every workspace member in canonical path order. See [Keiro DSL language versions](language-versions.md).
- `behavior-obligations` inventories every live transition, reachable rejection cell, and replay-only transition of the composed service, for a file or a workspace. See [behavior conformance and obligations](behavior-conformance.md).
- `check` exits non-zero on errors and optionally emits the normalized spec. `--explain-bindings` lists consumer-owned obligations; coverage reports inventory structural, opaque, explicit-`Json`, snapshot, and unsupported boundaries.
- `scaffold` validates, then emits generated modules and creates missing typed holes and binding skeletons. Read `semantic impact` independently from `generated-artifact impact`: the first names checked consumers and durable consequences; the second names changed bytes. `--goldens` embeds captured old-payload fixtures into the generated conformance harness so it exercises `decodeRaw` against real historical shapes. The codec-comparison pair emits an explicitly non-production historical comparison module for one persisted structural type.
- `diff` classifies changes as `ADDITIVE`, `WARNING`, or `BREAKING` from a six-surface compatibility vector and adds the same independent semantic-impact projection for mapped declarations. `--explain` prints paths, directions, rollout constraints, and remedies; `--report-out` writes stable JSON; repeated `--gate` options strengthen the default surface gate. `--emit-goldens` captures old-shape fixtures while both specifications exist, and `--replay-impact-out` drives the audit.

## Make warnings fail CI

A `keiro-dsl` warning is a real finding, and until 0.11 nothing stopped a repository from accumulating them. Gate them explicitly; severities themselves do not change.

```sh
keiro-dsl check domain/service.keiro-workspace \
  --min-language 5 \
  --deny-warnings \
  --report-out build/keiro-check.json
```

- `--deny-warnings` exits non-zero when any warning-severity diagnostic fires. Prefer it.
- `--deny CODE[,CODE...]` is the selective fallback when one idiomatic spelling warns by design — router and process benign-inversion spellings are the usual reason. It is repeatable and comma-separated. Deny the codes you accept, never the reverse.
- `--min-language N` enforces the effective-version floor. See [Keiro DSL language versions](language-versions.md).
- `--report-out FILE` writes the append-only `keiro-dsl/check-report/1` JSON — source or workspace — through `Keiro.Dsl.CheckReport`. Each entry carries its severity, code, location, and whether a `--deny` selection matched it, so CI can report the finding without re-parsing rendered text.

A denial that could never match is refused rather than silently ignored. `check --deny` rejects any code emitted only by `diff` or by the codec-comparison path, and rejects `CoverageOpaqueGateExceeded` outright because that code is the error `--fail-on-opaque` itself raises. If a `--deny` invocation is accepted, the code it names is genuinely reachable from that command.

## Clear the inert-declaration warnings

Keiro 0.11 started warning on spec surfaces the grammar accepts but no runtime implements — accepted intake bind flags, emit derivations, optional queue markers, and inline subscriptions. Scaffold reports additionally list emit, pgmq dispatch, and operation nodes that contribute no modules.

These are not stylistic. Each one names a declaration a reader would reasonably expect to have an effect and which has none. Delete it or replace it with the surface that does the work. From language 4 onward several of them are errors rather than warnings, so on an older source the warning is a preview of what adopting a current contract will reject.

Three surfaces are explicitly descriptive-only and are checked only for well-formedness: timer dead-letter text, pgmq fanout function names, and pgmq top-level dedupe keys. Do not read them as configuration; see [PGMQ jobs](../messaging/pgmq-jobs.md).

Language 5 does not make every accepted surface executable. Public integration contracts, category/all-history projection decoders, application SQL and DDL, queue-drain timing, and release coordination stay application-owned. Keep those boundaries visible in coverage rather than inferring consumers the checked graph cannot prove.

`diff` resolves the prior input with `git show`, including a workspace's historical manifest and member set, so repository context is mandatory. Any `BREAKING` result exits non-zero and is a deployment gate, not an informational warning. Review `WARNING` changes as behavior changes even though they do not fail the command; advisories such as `AggGuardTightened`, `AggFoldSurfaceChanged`, `RouterDecideSurfaceChanged`, `ProcessDecideSurfaceChanged`, `ProcessTimerPayloadChanged`, `OwnershipMoved`, and `WorkspaceAuthorityChanged` each carry an operator obligation described in [evolution gates and rollout ordering](evolution-and-rollout.md). Branch automation on the `DiagnosticCode`, not on the rendered text.

Capture goldens in the same change that bumps a version. Once the old specification is no longer the diff base, the old wire shape can only be recovered by hand from production data. For a brownfield migration, capture genuine stored JSON before writing the new declaration and compare the historical and generated codecs explicitly; synthesized fixtures cannot prove a candidate codec agrees with production history.

For the full grammar and examples, see the keiro repo's `docs/user/typed-spec-toolchain.md`.

## Related Patterns

- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Enforced identifier domains](identifier-domains.md)
- [Runtime assembly](runtime-assembly.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [Durable workflows](durable-workflows.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Composable service workspaces](service-workspaces.md)
- [Keiro DSL language versions](language-versions.md)
- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Typed field projections](../keiki/typed-field-projections.md)
- [Specification and scaffolding](../architecture/spec-and-scaffolding.md)
- [Semantic-local Keiro DSL regeneration](dsl-semantic-locality.md)
- [Mapped consumer surfaces](mapped-consumer-surfaces.md)
- [Typed projection catalogs](projection-catalogs.md)
