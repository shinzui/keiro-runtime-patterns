---
type: Standard
title: "Specification And Scaffolding"
description: "Placing a single-file or workspace Keiro source of truth, declaring consumer mappings, and running whole-service check/scaffold/conformance idempotently"
timestamp: 2026-07-29T12:40:01-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-spec-and-scaffolding
tags: [architecture, spec-and-scaffolding]
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
      Model technical-accuracy review against the mori-resolved danwa and keiro-runtime-jitsurei reference applications and the keiro-dsl scaffolder at HEAD; verified exported symbols, signatures, version claims, and links.
---

# Specification And Scaffolding

**Keep one service input — `domain/<service>.keiro` or `domain/<service>.keiro-workspace` — and regenerate the core package through the checked firewall.**

Keiro-dsl is a build-time toolchain, not a runtime interpreter. It checks a typed service specification and emits structural Haskell modules while preserving create-once hand-owned holes. The standard workflow makes the spec's placement choices explicit so every developer and CI run produces the same tree.

## Place The Service Contract At The Repository Root

A small service specification lives at `domain/<service>.keiro`. In the standard one-service-per-repository shape, begin it with the context and collocated-layout clauses:

```text
context ticket
layout collocated
```

The context supplies the default Haskell module root (`ticket` becomes `Ticket`) and identifies the service's DSL namespace. `layout collocated` places generated modules at `<Service>.<Node>.Generated.*` and holes beside them at `<Service>.<Node>.*`.

Keiro-dsl also supports a `module <Dotted.Prefix>` clause and the equivalent `--module-root` and `--collocate` command-line overrides. They exist for unusual namespaces and older specs. A standard fleet service records placement in its spec and needs no placement flags, preventing two scaffold invocations from silently choosing different trees.

Keiro-runtime-jitsurei keeps specs under `services/<name>/spec/` because it is a multi-service teaching monorepo. That accommodation is not the deployed-service standard.

When complete aggregates need separate source ownership, keep them as complete same-context `.keiro` files and make `domain/<service>.keiro-workspace` the service input:

```text
service ticket
module Ticket
layout collocated
spec ticket.keiro
spec ticket-audit.keiro
spec shared.keiro
```

The manifest owns the stable service identity and member set. Shared declarations have one owning member, and all file-taking commands target the manifest. Never run independent scaffolds for members that share one output tree: those runs see partial graphs and overwrite context-keyed history. See [composable service workspaces](../keiro/service-workspaces.md) for composition and adoption rules.

## Declare Consumer-Owned Types In The Same Source Of Truth

When a private aggregate payload or register uses an application type, declare it as `mapped structural` or `mapped opaque` before the aggregate. A structural declaration owns the complete private-event wire policy and names a total hand-owned binding, deterministic fixtures, stable canonical/binding identities, and any register initial. An opaque declaration names the consumer codec identity and version and makes no nested compatibility claim.

Do not create a second generated domain type merely to satisfy the DSL, and do not let both a consumer `ToJSON` instance and generated structural codec write current events. The generated codec is authoritative for structural private-event JSON; the binding converts domain values without owning wire rules.

## Check, Scaffold, Format, Test

Always run `check` before scaffolding, explain consumer bindings when mappings exist, target the core package's `src` directory, format the result, and run the generated domain harness. Here `SERVICE_INPUT` is the repository-relative `domain/<service>.keiro` or `domain/<service>.keiro-workspace` path. Danwa realizes the workflow by running the CLI from a keiro checkout because the executable is not installed globally:

```bash
# Run from the keiro checkout. Use absolute paths to the service repository.
cabal run -v0 keiro-dsl -- check \
  /path/to/<service>/SERVICE_INPUT \
  --explain-bindings \
  --coverage-report /path/to/<service>/build/keiro-coverage.json

cabal run -v0 keiro-dsl -- scaffold \
  /path/to/<service>/SERVICE_INPUT \
  --out /path/to/<service>/<service>-core/src

cd /path/to/<service>
nix fmt
cabal test <service>-core:<service>-core-domain
```

`check` resolves cross-node and mapped-type references and rejects incomplete or unsafe policy. `--explain-bindings` lists the exact binding, fixture, and initial signatures with consumer owners and aggregate use sites. The coverage report inventories named structural, opaque, `Json`, snapshot, and unsupported boundaries; it intentionally emits no aggregate percentage.

`scaffold` validates again before writing, reports created, overwritten, skipped, stale, and newly required paths or obligations, then emits the generated layer, aggregate holes, and consumer binding skeletons. Formatting is deterministic, so re-scaffold plus format is a no-op when neither the spec nor the generator has changed.

## Preserve The Firewall

Generated files carry the exact `-- @generated by keiro-dsl; do not edit. Regenerated from the .keiro spec.` banner and may be overwritten on every run. Hole and structural binding files are create-once: an existing hand-owned file is reported as skipped and its contents remain unchanged. The scaffolder plans the entire write before touching disk and refuses path collisions, unsafe identifiers, lowering failures, firewall breaches, a consumer module inside the generated namespace, import cycles, or a generated path whose existing file lacks the banner.

Do not use `--force-generated-overwrite` in an ordinary workflow. It bypasses the missing-banner protection for generated paths and is appropriate only after a human has proved the existing file is disposable.

Each successful single-file run writes informational `keiro-dsl-manifest.<context>.txt` and `keiro-dsl-scaffold-record.<context>.txt` files. A workspace instead writes `keiro-dsl-manifest.workspace.<service>.txt` and `keiro-dsl-scaffold-record.workspace.<service>.txt`; the record attributes aggregate modules to their member and marks service-wide modules as context-level. The generated manifest includes Cabal `other-modules`, dependencies, and consumer package/module requirements. Gitignore it. The stale-path report is advisory: keiro-dsl never deletes modules that a changed service input no longer emits. Review each stale generated and hand-owned candidate, remove obsolete files deliberately, and keep any adopted hand code under an appropriate non-generated name.

The first structural scaffold emits private `Structural.Shape.*` modules and one `StructuralProjections` facade and creates the declared binding module. Fill total conversion functions, deterministic fixtures, and required initials, then run the generated harness. Exact nominal types may opt into `genericStructuralBinding`; any constructor, selector, order, arity, or field-type mismatch must use the explicit skeleton.

## Evolve The Specification, Not Generated Haskell

Change node or mapped-type structure in the owning member, run `check` and `scaffold` against the service input, and review the whole-service report. For a release, also apply the evolution gate from the [keiro-dsl adoption standard](../keiro/dsl-adoption.md): run `keiro-dsl diff SERVICE_INPUT --since <git-ref> --explain` from the repository containing the service contract, review its six-surface compatibility vector, and block deployment on every finding breaking the configured gate.

For a brownfield structural mapping, capture production JSON before declaring the shape and request an explicit non-production comparison module with `--codec-comparison TYPE --comparison-out FILE`. Compile it beside the historical codec and require canonical JSON parity or explicit version/upcaster work. See [brownfield Keiro adoption](../keiro/brownfield-adoption.md).

## Related Patterns

- [Vertical-slice modules](vertical-slice-modules.md)
- [Keiro-dsl adoption](../keiro/dsl-adoption.md)
- [ADR 0002: adopt keiro-dsl](https://github.com/shinzui/keiro-runtime-patterns/blob/master/docs/adr/0002-adopt-keiro-dsl-for-contracts-and-evolution.md)
- [Checked composition](../keiki/checked-composition.md)
- [Brownfield Keiro adoption](../keiro/brownfield-adoption.md)
- [Composable service workspaces](../keiro/service-workspaces.md)
