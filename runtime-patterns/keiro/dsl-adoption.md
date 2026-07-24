---
type: Guide
title: "Keiro-dsl adoption"
description: "When to adopt keiro-dsl, its generated-code firewall, holes, CLI, and evolution gate"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-dsl-adoption
tags: [keiro, dsl-adoption]
status: current
---

# Keiro-dsl adoption

**Adopt keiro-dsl for cross-node contracts and evolution safety; skip it only when there is nothing substantive for it to check.**

This guide decides when a service should own a checked `.keiro` specification and where generated structure stops and hand-written domain logic begins.

## Apply the adoption rule

Adopt keiro-dsl when a service has more than one node family, any integration surface such as intake, emit, or queues, or expected schema/workflow evolution. The checker and evolution gate are the payoff, and their value grows with every contract edge.

A trivial single-aggregate service may hand-write against the public API only when it has no queues, integration contracts, or workflow evolution. Revisit that choice as soon as a second node family or evolution concern appears; `keiro-dsl new` and `check` make retrofitting cheap.

Keiro-dsl is a build-time parser, checker, scaffolder, harness emitter, and evolution differ—not a runtime interpreter. The `keiro-dsl` library has no dependency on `keiro`; generated and conformance code use the same public runtime APIs as hand-written services.

## Let the checker own cross-node contracts

The rule is one sentence: put mechanically checkable identity, policy, and evolution relationships in the specification instead of reconstructing them in modules or prose.

The grammar covers aggregates and upcasters, projections and snapshots, process managers and timers, routers, integration contracts, inbox/outbox nodes, publishers, PGMQ work queues and dispatch, read models, and durable workflows. The checker verifies, among other contracts:

- complete intake and work-queue disposition tables, including dangerous retry/ack inversions;
- FIFO group-key requirements and captured opaque derivations;
- snapshot codec identity, live shape hashes, status-map totality, and contiguous upcasters;
- duplicate and incomplete aggregate upcaster chains, and the mutually exclusive `retiring event` marker;
- event retirement discipline: a deprecated event with no replay-only emitter, and a replay-only transition that emits nothing or has no live sibling;
- workflow signal/await matching, unique labels, and terminal `continueAsNew`;
- resolved cross-node references and rejection handling that never marks `CommandAmbiguous` benign.

Given the same tool version, specification, and placement options, scaffolding is deterministic; committed conformance modules pin generated output byte-for-byte.

## Keep domain decisions behind the firewall

The rule is absolute: **never edit a generated module**. Change the specification and scaffold again, or implement the hand-owned hole.

Generated modules carry `-- @generated` and are overwritten on every scaffold. `HoleStub` modules are create-once and skipped thereafter. The `FirewallSurface` checked by `firewallBreaches` prevents generated modules from containing keiki decision operators and builders such as `.==`, `./=`, `.||`, `lit`, or the `B` builder qualifier. Domain decide logic is always hand-owned, whether or not the service adopts the DSL.

The default layout is `Generated.<Context>.<Node>` with holes under the domain namespace. `--collocate` instead places generated code at `<Context>.<Node>.Generated` beside the hand-owned layer. Scaffolding reports stale paths but never deletes them; review stale generated and hand-owned files separately.

## Recognize the eight hole kinds

1. Deterministic identifier or string derivation; opaque strategies carry a captured fixture, never only a prose rule.
2. Failure-to-action disposition, including ack, bounded retry, and dead-letter choices.
3. Explicit value-to-value mapping rather than an assumed identity conversion.
4. Envelope-field layering, cross-check, and deduplication policy.
5. Define-once stable names and contracts that generated modules reference rather than retype.
6. Body decode strictness and schema-version policy.
7. Emit optionality, made total with an explicit `_ => skip` catch-all.
8. Deployment configuration such as Kafka brokers, `groupId`, `offsetReset`, metrics, shards, and runtime tuning.

## Use only named escape hatches

Use `ResolveHole` when a router needs a typed hand-owned resolver instead of a read model. Keep opaque queue group-key derivation hand-owned and capture its fixture in the spec. Implement PGMQ dispatch fan-out and its raw-SQL dedup predicate in typed holes. Leave deployment configuration in hole kind 8.

`--force-generated-overwrite` is a repair footgun: it bypasses only the safety refusal for an existing generated path that lacks the banner. It can clobber a hand-edited file and is permitted only after confirming that file is disposable.

## Use the complete CLI loop

Run these commands from the Git repository containing the specification:

```sh
keiro-dsl new KIND
keiro-dsl parse FILE
keiro-dsl check FILE [--emit]
keiro-dsl scaffold FILE --out DIR \
  [--module-root PREFIX] [--collocate] [--force-generated-overwrite] \
  [--goldens DIR]
keiro-dsl diff FILE --since GIT-REF \
  [--emit-goldens DIR] [--replay-impact-out FILE]
```

- `new` prints a skeleton for aggregate, process, router, contract, intake, emit, publisher, workqueue, dispatch, workflow, or operation.
- `parse` parses and pretty-prints a normalized specification.
- `check` exits non-zero on errors and optionally emits the normalized spec.
- `scaffold` validates, then emits generated modules and creates missing typed holes. `--goldens` embeds captured old-payload fixtures into the generated conformance harness so it exercises `decodeRaw` against real historical shapes.
- `diff` classifies changes as `ADDITIVE`, `WARNING`, or `BREAKING`. `--emit-goldens` captures old-shape fixtures for event version bumps while both specifications still exist, never overwriting an existing file. `--replay-impact-out` writes the machine-readable replay verdict that drives the audit.

`diff` resolves the prior file with `git show`, so repository context is mandatory. Any `BREAKING` result exits non-zero and is a deployment gate, not an informational warning. Review `WARNING` changes as behavior changes even though they do not fail the command; advisories such as `AggGuardTightened`, `AggFoldSurfaceChanged`, `RouterDecideSurfaceChanged`, `ProcessDecideSurfaceChanged`, and `ProcessTimerPayloadChanged` each carry an operator obligation described in [evolution gates and rollout ordering](evolution-and-rollout.md). Branch automation on the `DiagnosticCode`, not on the rendered text.

Capture goldens in the same change that bumps a version. Once the old specification is no longer the diff base, the old wire shape can only be recovered by hand from production data.

For the full grammar and examples, see the keiro repo's `docs/user/typed-spec-toolchain.md`.

## Related Patterns

- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Runtime assembly](runtime-assembly.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [Durable workflows](durable-workflows.md)
- The forthcoming architecture standard defines the fleet's `Generated.*` and hole-module placement.
