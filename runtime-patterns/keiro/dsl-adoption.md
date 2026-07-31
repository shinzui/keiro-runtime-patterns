---
type: Guide
title: "Keiro-dsl adoption"
description: "When to adopt keiro-dsl, including composable service workspaces, brownfield structural mappings, the generated-code firewall, conformance evidence, and evolution gates"
timestamp: 2026-07-31T16:04:17-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-dsl-adoption
tags: [keiro, dsl-adoption]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T12:40:01-07:00
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

This guide decides when a service should own a checked `.keiro` contract — one file or a composed `.keiro-workspace` — and where generated structure stops and hand-written domain logic begins.

## Apply the adoption rule

Adopt keiro-dsl when a service has more than one node family, any integration surface such as intake, emit, or queues, expected schema/workflow evolution, existing private-event history, or a consumer-owned value whose wire shape and decision fields must be checked. The checker, generated conformance harness, and evolution gate are the payoff, and their value grows with every durable contract edge.

A trivial single-aggregate service may hand-write against the public API only when it has no queues, integration contracts, mapped persisted values, existing history, or expected evolution. Revisit that choice as soon as any of those appear. Structural mappings make retrofit adoption possible without replacing the service's Haskell domain types with generated equivalents.

Keiro-dsl is a build-time parser, checker, scaffolder, harness emitter, and evolution differ—not a runtime interpreter. The `keiro-dsl` library has no dependency on `keiro`; generated and conformance code use the same public runtime APIs as hand-written services.

## Let the checker own cross-node contracts

The rule is one sentence: put mechanically checkable identity, policy, and evolution relationships in the specification instead of reconstructing them in modules or prose.

The grammar covers aggregates and upcasters, projections and snapshots, process managers and timers, routers, integration contracts, inbox/outbox nodes, publishers, PGMQ work queues and dispatch, read models, and durable workflows. The checker verifies, among other contracts:

- complete intake and work-queue disposition tables, including dangerous retry/ack inversions;
- FIFO group-key requirements and captured opaque derivations;
- snapshot codec identity, live shape hashes, status-map totality, and contiguous upcasters;
- duplicate and incomplete aggregate upcaster chains, and the mutually exclusive `retiring event` marker;
- event retirement discipline: a deprecated event with no replay-only emitter, and a replay-only transition that emits nothing or has no live sibling;
- structural and opaque consumer mappings: total resolved type graphs, canonical and binding identities, injective wire policy, register initials, and complete consumer obligations;
- workflow signal/await matching, unique labels, and terminal `continueAsNew`;
- resolved cross-node references and rejection handling that never marks `CommandAmbiguous` benign.

Given the same tool version, service input, and placement options, scaffolding is deterministic; committed conformance modules pin generated output byte-for-byte. A workspace composes complete same-context members before validation, so cross-member references and conflicts are checked as one service rather than by unrelated invocations.

## Keep domain decisions behind the firewall

The rule is absolute: **never edit a generated module**. Change the specification and scaffold again, or implement the hand-owned hole.

Generated modules carry `-- @generated` and are overwritten on every scaffold. `HoleStub` modules are create-once and skipped thereafter. The `FirewallSurface` checked by `firewallBreaches` prevents generated modules from containing keiki decision operators and builders such as `.==`, `./=`, `.||`, `lit`, or the `B` builder qualifier.

That firewall has exactly one exemption: the version-2 generated `Expressions` and `Transducer` modules, which are the intended generated authority for declared scalar guards and writes. Under language version 2 the spec, not a hand-written module, owns scalar decide logic for a generated transition; behavior the scalar language cannot express is marked `implementation hole` and stays hand-owned. Under version 1 every aggregate decide body remains hand-owned as before. See [aggregate scalar expressions and transition ownership](aggregate-expressions.md).

The default layout is `Generated.<Context>.<Node>` with holes under the domain namespace. `--collocate` instead places generated code at `<Context>.<Node>.Generated` beside the hand-owned layer. Structural mappings additionally emit private `Structural.Shape.*` modules and one `StructuralProjections` facade. Their binding, fixture, and optional register-initial modules are create-once, hand-owned files at the qualified modules named by the mapping declarations.

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

Use `mapped nominal`, a bound `id`, or a bound `enum` when the consumer type is a total isomorphism over a single scalar, ID, or closed enumeration — the binding then keeps the application type in direct command, event, and register fields. It requires language version 2 and carries its own obligations; see [consumer-owned nominal bindings](nominal-bindings.md).

Generated `StructuralProjections` witnesses let a hand-owned Keiki transducer use `regProj` and `inpProj` for eligible scalar guards while commands, registers, and events retain the consumer type. Projections are direct-base and guard-only; they do not lower nested `.keiro` paths into the transducer. Under language version 2 the generated expression modules use the same witnesses for checked dotted paths. See [Brownfield Keiro Adoption](brownfield-adoption.md) for the end-to-end choice and migration sequence.

## Use the complete CLI loop

Run these commands from the Git repository containing the specification:

```sh
keiro-dsl new KIND
keiro-dsl parse INPUT
keiro-dsl pretty INPUT
keiro-dsl inspect INPUT --format=json
keiro-dsl check INPUT [--emit] [--explain-bindings] \
  [--coverage-report FILE] [--fail-on-opaque]
keiro-dsl scaffold INPUT --out DIR \
  [--module-root PREFIX] [--collocate] [--force-generated-overwrite] \
  [--goldens DIR] \
  [--codec-comparison TYPE --comparison-out FILE]
keiro-dsl diff INPUT --since GIT-REF \
  [--emit-goldens DIR] [--replay-impact-out FILE] [--explain] \
  [--report-out FILE] [--gate SURFACE] \
  [--coverage-report FILE] [--fail-on-opaque-increase]
```

- `new` prints a skeleton for aggregate, process, router, contract, intake, emit, publisher, workqueue, dispatch, workflow, or operation.
- `INPUT` is either one `.keiro` file or a `.keiro-workspace` manifest. Use the manifest whenever complete aggregates live in separate members; all file-taking commands operate on the composed service.
- `parse` parses and pretty-prints the normalized service specification; `pretty` is the explicit alias for that canonical render. Neither one rewrites a source's language declaration.
- `inspect --format=json` reports whether each source declared a language version and which version is effective, for a file or for every workspace member in canonical path order. See [Keiro DSL language versions](language-versions.md).
- `check` exits non-zero on errors and optionally emits the normalized spec. `--explain-bindings` lists consumer-owned obligations; coverage reports inventory structural, opaque, explicit-`Json`, snapshot, and unsupported boundaries.
- `scaffold` validates, then emits generated modules and creates missing typed holes and binding skeletons. `--goldens` embeds captured old-payload fixtures into the generated conformance harness so it exercises `decodeRaw` against real historical shapes. The codec-comparison pair emits an explicitly non-production historical comparison module for one persisted structural type.
- `diff` classifies changes as `ADDITIVE`, `WARNING`, or `BREAKING` from a six-surface compatibility vector. `--explain` prints paths, directions, rollout constraints, and remedies; `--report-out` writes stable JSON; repeated `--gate` options strengthen the default surface gate. `--emit-goldens` captures old-shape fixtures while both specifications exist, and `--replay-impact-out` drives the audit.

`diff` resolves the prior input with `git show`, including a workspace's historical manifest and member set, so repository context is mandatory. Any `BREAKING` result exits non-zero and is a deployment gate, not an informational warning. Review `WARNING` changes as behavior changes even though they do not fail the command; advisories such as `AggGuardTightened`, `AggFoldSurfaceChanged`, `RouterDecideSurfaceChanged`, `ProcessDecideSurfaceChanged`, `ProcessTimerPayloadChanged`, `OwnershipMoved`, and `WorkspaceAuthorityChanged` each carry an operator obligation described in [evolution gates and rollout ordering](evolution-and-rollout.md). Branch automation on the `DiagnosticCode`, not on the rendered text.

Capture goldens in the same change that bumps a version. Once the old specification is no longer the diff base, the old wire shape can only be recovered by hand from production data. For a brownfield migration, capture genuine stored JSON before writing the new declaration and compare the historical and generated codecs explicitly; synthesized fixtures cannot prove a candidate codec agrees with production history.

For the full grammar and examples, see the keiro repo's `docs/user/typed-spec-toolchain.md`.

## Related Patterns

- [Evolution gates and rollout ordering](evolution-and-rollout.md)
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
