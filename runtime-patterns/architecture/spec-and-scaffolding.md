---
type: Standard
title: "Specification And Scaffolding"
description: "Placing a Keiro service source of truth, declaring mapped consumers, and running semantic-local whole-service check, scaffold, and conformance"
timestamp: 2026-09-06T21:22:15Z
generated:
  by: process:codex
  at: "2026-09-06T21:22:15Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-spec-and-scaffolding
tags: [architecture, spec-and-scaffolding]
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
      Model technical-accuracy review against the mori-resolved danwa and keiro-runtime-jitsurei reference applications and the keiro-dsl scaffolder at HEAD; verified exported symbols, signatures, version claims, and links.
---

# Specification And Scaffolding

**Keep one workspace service input at `domain/<service>.keiro-workspace` and regenerate the core package through the checked firewall; reserve a bare `.keiro` input for a trivial domain with exactly one aggregate.**

Keiro-dsl is a build-time toolchain, not a runtime interpreter. It checks a typed service specification and emits structural Haskell modules while preserving create-once hand-owned holes. The standard workflow makes the spec's placement choices explicit so every developer and CI run produces the same tree.

## Place The Service Contract At The Repository Root

In the standard one-service-per-repository shape, version `domain/<service>.keiro-workspace` and keep its members under `domain/<service>/`. The manifest owns service-wide placement and lists each complete aggregate member plus any explicitly owned shared member:

```text
service ticket
module Ticket
layout collocated
runtime-package ticket-service
spec ticket/shared.keiro
spec ticket/ticket.keiro
```

Every member begins with the language preamble and context:

```text
language keiro-dsl 5
context ticket
```

The `language` clause must be the first significant clause and is required of every new source. Version 5 is the sole published stable authoring contract; versions 1 through 4 remain readable as compatibility-only and make the CLI emit a stderr contract notice. `keiro-dsl new` follows `currentAuthoringLanguageVersion`, which selects a candidate contract when the registry holds one, so verify the preamble before using a generated skeleton in a production service. See [Keiro DSL language versions](../keiro/language-versions.md). The shared context identifies the service's DSL namespace. The manifest's `module` supplies the Haskell module root, while `layout collocated` places generated modules at `<Service>.<Node>.Generated.*` and holes beside them at `<Service>.<Node>.*`.

Keiro-dsl also supports a `module <Dotted.Prefix>` clause and the equivalent `--module-root` and `--collocate` command-line overrides. They exist for unusual namespaces and older specs. A standard fleet service records placement in its contract and needs no placement flags, preventing two scaffold invocations from silently choosing different trees.

Keiro-runtime-jitsurei keeps specs under `services/<name>/spec/` because it is a multi-service teaching monorepo. That accommodation is not the deployed-service standard.

Use a bare `domain/<service>.keiro` only for a trivial domain with exactly one aggregate whose entire contract remains comfortably readable in one file. In that exception, place `module` and `layout collocated` in the source itself. A non-trivial single-aggregate domain uses a workspace, and any bare source becomes a workspace as soon as a second aggregate or meaningful source boundary appears.

The manifest owns the stable service identity and member set. Each aggregate stays whole in one member, shared declarations have one owning member, and all file-taking commands target the manifest. Never run independent scaffolds for members that share one output tree: those runs see partial graphs and overwrite context-keyed history. See [composable service workspaces](../keiro/service-workspaces.md) for composition, growth, and adoption rules.

## Declare Consumer-Owned Types In The Same Source Of Truth

When a private aggregate payload or register uses an application type, first apply [domain newtypes and TypeIDs](domain-newtypes-and-typeids.md): the application type must be nominal rather than a raw primitive or type synonym, and every service-owned ID must be TypeID-backed. Then declare it before the aggregate as `mapped structural`, `mapped opaque`, or — under language version 2 — a nominal binding. A structural declaration owns the complete private-event wire policy and names a total hand-owned binding, deterministic fixtures, stable canonical/binding identities, and any register initial. An opaque declaration names the consumer codec identity and version and makes no nested compatibility claim. A nominal binding (`id … using`, `enum … using`, or `mapped nominal`) keeps a consumer type in a direct field across a total isomorphism; see [consumer-owned nominal bindings](../keiro/nominal-bindings.md).

Do not create a second generated domain type merely to satisfy the DSL, and do not let both a consumer `ToJSON` instance and generated structural codec write current events. The generated codec is authoritative for structural private-event JSON; the binding converts domain values without owning wire rules.

Language 5 carries the same mapped declarations through persisted workqueue payloads, paired read-model query contracts, and aggregate-sourced projection handlers. Declare those consumers in the specification and apply their independent drain, caller-build, handler-review, and group-rebuild consequences from [mapped consumer surfaces](../keiro/mapped-consumer-surfaces.md).

## Check, Scaffold, Format, Test

Always run `check` before scaffolding, explain consumer bindings when mappings exist, target the core package's `src` directory, format the result, and run the generated domain harness. Here `SERVICE_INPUT` is normally the repository-relative `domain/<service>.keiro-workspace` path; only the trivial single-aggregate exception uses `domain/<service>.keiro`. Danwa realizes the workflow by running the CLI from a keiro checkout because the executable is not installed globally:

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

`check` resolves cross-node and mapped-type references and rejects incomplete or unsafe policy. `--explain-bindings` lists the exact binding, fixture, and initial signatures with consumer owners and typed roots. The coverage report inventories named structural, opaque, `Json`, snapshot, and unsupported boundaries; it intentionally emits no aggregate percentage.

`scaffold` validates again before writing, reports created, overwritten, skipped, stale, and newly required paths or obligations, then emits the generated layer, aggregate holes, and consumer binding skeletons. It reports checked `semantic impact` independently from `generated-artifact impact`; do not infer one from the other. Formatting is deterministic, so re-scaffold plus format is a no-op when neither the spec nor the generator has changed.

## Preserve The Firewall

Generated files carry the exact `-- @generated by keiro-dsl; do not edit. Regenerated from the .keiro spec.` banner and may be overwritten on every run. Hole and structural binding files are create-once: an existing hand-owned file is reported as skipped and its contents remain unchanged. The scaffolder plans the entire write before touching disk and refuses path collisions, unsafe identifiers, lowering failures, firewall breaches, a consumer module inside the generated namespace, import cycles, or a generated path whose existing file lacks the banner.

Do not use `--force-generated-overwrite` in an ordinary workflow. It bypasses the missing-banner protection for generated paths and is appropriate only after a human has proved the existing file is disposable.

Each successful scaffold writes informational sidecars named for the role they play:

| Sidecar | Single file | Workspace |
|---|---|---|
| Scaffold ledger | `keiro-dsl-ledger.context.<context>.txt` | `keiro-dsl-ledger.workspace.<service>.txt` |
| Cabal fragment | `keiro-dsl-cabal-fragment.context.<context>.txt` | `keiro-dsl-cabal-fragment.workspace.<service>.txt` |
| Conformance ledger | `keiro-dsl-conformance-ledger.txt` | `keiro-dsl-conformance-ledger.txt` |

The workspace ledger attributes aggregate modules to their member, marks service-wide modules as context-level, and persists a source-independent `semantic-impact` snapshot. A ledger predating that row reports an unavailable baseline on the first new run; it does not infer an empty prior graph. The Cabal fragment includes `other-modules`, dependencies, consumer package/module requirements, `default-language`, `default-extensions`, and an `exposed-modules` block for the conformance facade — the complete fragment, which consumers repaste rather than merge by hand. Gitignore it. The stale-path report is advisory: keiro-dsl never deletes modules that a changed service input no longer emits. Review each stale generated and hand-owned candidate, remove obsolete files deliberately, and keep any adopted hand code under an appropriate non-generated name.

The conformance ledger uses the versioned `keiro-dsl conformance ledger v1` format with typed JSON file rows. Its parser ignores unknown row kinds and JSON keys, so a newer toolchain's ledger stays readable, but it still refuses a bad service key, a malformed record, an unsafe path, or a case-folded duplicate path.

## Migrate Legacy Sidecar Names Explicitly

Keiro 0.11 renamed every sidecar from the `keiro-dsl-manifest.*` / `keiro-dsl-scaffold-record.*` spellings. **A tree still holding the old names refuses to scaffold and writes nothing** — this is a hard stop, not a warning, reported as `SidecarMigrationRequired` or `SidecarMigrationRefusal`.

Read the listed moves. On the current generator a pre-v2 ledger also requires edition adoption; keep the normal output and build arguments and apply both operations together:

```bash
keiro-dsl scaffold SERVICE_INPUT --out GENERATED_ROOT \
  --apply-name-migrations --apply-generated-haskell-edition
```

The apply path is backup-backed and digest-journaled, with crash recovery, and it rewrites Haskell module references token-aware rather than by text substitution. Duplicate old files that cannot be renamed losslessly are preserved under `.keiro-dsl-name-migrations/sidecar-v1/`. Legacy conformance records are converted only by this explicit path; nothing is upgraded implicitly.

The same run migrates generated Haskell names. Keiro 0.11 moved generated modules onto one checked UpperCamelCase/lowerCamelCase naming edition, so compound paths change (`Service_oncall` becomes `ServiceOncall`). These are generated-only renames: they are consumer-build advisories, and external and replay identities do not move. `ScaffoldReport` and `WorkspaceScaffoldReport` carry the applied moves, so review them before committing.

A ledger without a `naming-edition` row means `legacy-v1`; an existing ledger that cannot be parsed is a refusal, never an absent history. Both `legacy-v1` and `idiomatic-v1` require explicit migration to `idiomatic-v2`, including sidecar-only legacy trees. Follow [generated Haskell editions](../keiro/generated-haskell-editions.md) for backup scope, hand-owned selector remediation, and complete rollback.

The first structural scaffold emits private `Structural.Shape.*` modules and one `StructuralProjections` facade and creates the declared binding module. Fill total conversion functions, deterministic fixtures, and required initials, then run the generated harness. Exact nominal types may opt into `genericStructuralBinding`; any constructor, selector, order, arity, or field-type mismatch must use the explicit skeleton. A nominal binding additionally emits create-once binding skeletons, a context-level `NominalProjections` facade, and any private enum-representation leaf modules, and records them in additive `nominal-mapping` rows.

The semantic-local scaffold additionally emits one context `StructuralConformance` and one context `BehaviorSourceMap`. The former owns declaration-wide laws once for the service; aggregate harnesses retain only use-specific evidence in their checked closures. The latter maps stable behavior keys to current source positions so source movement does not churn semantic contracts. Repaste both from the Cabal fragment and run the generated service conformance target after adoption. See [semantic-local regeneration](../keiro/dsl-semantic-locality.md).

From language version 2 each aggregate also gets generated `Expressions` and `Transducer` modules. They are the one exemption to the symbolic-operator firewall, because they are the generated authority that builds Keiki terms from declared guards and writes. Every such transition is generated-owned or explicitly `implementation hole`; see [aggregate scalar expressions and transition ownership](../keiro/aggregate-expressions.md).

A configured service additionally scaffolds at most one local conformance package behind a single generated `<Generated prefix>.Conformance` facade. See [the generated compilation contract](generated-compilation-contract.md) for the package, its runtime-package authority, and the language pragmas generated modules may declare.

## Evolve The Specification, Not Generated Haskell

Change node or mapped-type structure in the owning member, run `check` and `scaffold` against the service input, and review both the semantic and artifact projections of the whole-service report. For a release, also apply the evolution gate from the [keiro-dsl adoption standard](../keiro/dsl-adoption.md): run `keiro-dsl diff SERVICE_INPUT --since <git-ref> --explain` from the repository containing the service contract, review its six-surface compatibility vector and mapped consequences, and block deployment on every finding breaking the configured gate.

For a brownfield structural mapping, capture production JSON before declaring the shape and request an explicit non-production comparison module with `--codec-comparison TYPE --comparison-out FILE`. Compile it beside the historical codec and require canonical JSON parity or explicit version/upcaster work. See [brownfield Keiro adoption](../keiro/brownfield-adoption.md).

## Related Patterns

- [Vertical-slice modules](vertical-slice-modules.md)
- [Domain newtypes and TypeIDs](domain-newtypes-and-typeids.md)
- [Keiro-dsl adoption](../keiro/dsl-adoption.md)
- [ADR 0002: adopt keiro-dsl](https://github.com/shinzui/keiro-runtime-patterns/blob/master/docs/adr/0002-adopt-keiro-dsl-for-contracts-and-evolution.md)
- [Checked composition](../keiki/checked-composition.md)
- [Brownfield Keiro adoption](../keiro/brownfield-adoption.md)
- [Composable service workspaces](../keiro/service-workspaces.md)
- [Keiro DSL language versions](../keiro/language-versions.md)
- [Aggregate scalar expressions and transition ownership](../keiro/aggregate-expressions.md)
- [Semantic-local Keiro DSL regeneration](../keiro/dsl-semantic-locality.md)
- [Mapped consumer surfaces](../keiro/mapped-consumer-surfaces.md)
