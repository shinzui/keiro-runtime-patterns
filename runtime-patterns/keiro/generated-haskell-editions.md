---
type: Guide
title: "Generated Haskell edition migration"
description: "Adopting idiomatic-v2 record APIs through an explicit scaffold gate, durable backups, complete compilation, and recoverable rollback"
timestamp: 2026-09-06T21:22:15Z
generated:
  by: process:codex
  at: "2026-09-06T21:22:15Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-generated-haskell-editions
tags: [keiro, generated-haskell-editions]
status: current
---

# Generated Haskell edition migration

**Adopt `idiomatic-v2` with an explicit scaffold migration, migrate every hand-owned record consumer, and compile the complete service before accepting the new ledger.**

Keiro-dsl 0.15 changes package product records and generated Haskell to concise repeated labels with record-dot reads. The generated edition changes Haskell presentation; it does not change `.keiro` language semantics, constructor arity or field order, JSON and wire keys, SQL names, runtime identities, diagnostics, or fingerprints. Keep the [source-language migration](language-versions.md) and the generated-edition gate distinct.

## Inspect the refusal with the ordinary command

Run the service's usual `keiro-dsl scaffold` command with its normal workspace, output directory, module root, layout, goldens, and runtime-package arguments. An `idiomatic-v1` or `legacy-v1` ledger refuses ordinary scaffolding before writes. A ledger with no `naming-edition` row is `legacy-v1`; a corrupt existing ledger is a refusal, not a new tree. Never delete or edit the ledger to bypass adoption.

Review the reported Generated paths, ledger, Cabal fragment, and attributable uses in recorded Hole files. The lexical scanner reports prefix and qualified selectors, renamed record-dot uses, record-field bindings, and operator operands. It does not understand every application source; compilation remains authoritative beyond its inventory.

## Migrate hand-owned consumers

Use concise record dot (`value.label`) or constructor-directed matching and construction. Package-authored public product selector functions and owner-prefixed labels are removed. Importing the old selector, composing it as a function, or enabling record dot without renaming its label does not migrate the call site.

Before edition apply, use positional construction or positional patterns for renamed labels; constructor order is stable across editions. For an unchanged concise label, enable `OverloadedRecordDot` locally and use dot syntax while the old fragment remains active. Preserve only the explicit single-field newtype unwrappers that upstream publishes. Do not restore product selectors with `FieldSelectors`, compatibility aliases, or generic-lens shims.

Package consumers must also preserve [checked construction boundaries](language-versions.md): use supported projections for abstract values and obtain prepared migrations from preflight. Public record migration does not expose hidden constructors or internal generator modules.

Consult the exhaustive producer inventories in `mori://shinzui/keiro`, project-relative paths `keiro-dsl/record-field-migration-0.15.md` and `keiro-dsl/generated-haskell-edition-idiomatic-v2.md` (artifact-level URIs pending). Use their per-owner mappings rather than stripping prefixes mechanically. In generated behavior code, for example, `reportRequired` becomes `report.required`, `witnessHistory` becomes `witness.history`, and `sourceFile` becomes `source.file`; JSON keys remain unchanged.

## Apply all required migrations together

Rerun the same command with the edition flag:

```sh
keiro-dsl scaffold domain/service.keiro-workspace --out src \
  --apply-generated-haskell-edition
```

When legacy sidecar names or generated module names also need migration, pass both flags in one run, including for sidecar-only legacy trees:

```sh
keiro-dsl scaffold domain/service.keiro-workspace --out src \
  --apply-name-migrations --apply-generated-haskell-edition
```

Retain all other arguments from the ordinary command. Either flag alone leaves a combined legacy migration refused. Sidecars move first, then the ledger is reread under its current name; the edition backup captures recorded files at their pre-module-move paths before the separate generated-name migration runs. Collision, banner, overwrite, package, and workspace preflights still apply. `--force-generated-overwrite` does not bypass the edition gate. A flagged run can move sidecars before a later preflight refuses; inspect its applied-move report rather than treating every failure as write-free.

## Preserve the backup boundary

Before overwriting, the edition migration copies every existing ledger-recorded Generated file and the current ledger and Cabal fragment beneath the output root:

```text
.keiro-dsl-generated-haskell-migrations/<from>-to-idiomatic-v2/
```

A backup already containing different bytes is a hard refusal. The directory's `remediation-report.txt` is regenerated on each apply; it is mutable reporting, not immutable conflict evidence. Create-once Hole and binding files remain hand-owned and are not copied, moved, or rewritten by edition adoption. The generated conformance package's own files are outside this backup set; account for them separately in version control and rollback.

## Reconcile and prove the build

Repaste the complete [Cabal fragment](../architecture/generated-compilation-contract.md). The baseline is `GHC2024` with `DuplicateRecordFields`, `NoFieldSelectors`, `OverloadedRecordDot`, and `OverloadedStrings`. Compile the whole consuming component, including hand-owned Hole and binding modules, and the generated conformance package. Run behavior, structural, codec, replay, and application checks; an unchanged `.keiro` file does not make this Haskell API migration compile automatically.

Read generated-artifact changes independently from [semantic impact](dsl-semantic-locality.md). Expect renamed Haskell fields and changed generated bytes; require stable wire observations and fingerprints when the specification is unchanged. A successful second scaffold is an ordinary idempotent v2 run.

## Restore a complete edition after interruption

Inspect backups before retrying an interrupted apply. While the ledger still records the old edition, the tool accepts byte-identical backup evidence or refuses a conflict. Resolve conflicts by restoring the complete backed-up relative-path set to the output root, including ledger and fragment; never mix old metadata with v2 modules. Restore or regenerate conformance-package files separately because the edition backup does not own them.

For a combined `legacy-v1` adoption, also remove the source-move destinations listed in the remediation report and restore their originals from `.keiro-dsl-name-migrations/legacy-v1-to-idiomatic-v1/`. Keep the complete version-control baseline when restoring old sidecar names as well. The remediation report may remain during rollback, Hole edits, and retry; do not delete immutable backups to silence a conflict.

Once the ledger records `idiomatic-v2`, ordinary scaffolding does not rerun old-edition backup conflict checks. Do not interpret an ordinary successful rerun as proof that later hand edits were part of the migration backup.

## Related Patterns

- [Keiro-dsl adoption](dsl-adoption.md)
- [Specification and scaffolding](../architecture/spec-and-scaffolding.md)
- [The generated compilation contract](../architecture/generated-compilation-contract.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Keiro DSL language versions](language-versions.md)
- [Semantic-local regeneration](dsl-semantic-locality.md)
