---
type: Standard
title: "The generated compilation contract"
description: "The GHC2024 baseline generated Haskell compiles under, the closed extension set a module may request locally, and the conformance package and runtime-package authority a configured service scaffolds"
timestamp: 2026-08-05T19:47:25-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-generated-compilation-contract
tags: [architecture, generated-compilation-contract]
status: current
---

# The generated compilation contract

**Generated Haskell states how it must be compiled; the consuming package satisfies that statement rather than guessing at it.**

Before Keiro 0.10 a service repository inferred what the generated layer needed — which extensions, which package the conformance runner compiled against, which modules to expose. Each inference was a place the build could drift from the generator. The contract is now explicit and checked, and the service side's job is to honour it exactly.

## Repaste the Cabal fragment; do not hand-merge it

The scaffolder writes a complete Cabal fragment sidecar — `keiro-dsl-cabal-fragment.context.<context>.txt`, or the `.workspace.<service>.txt` form. It owns:

- `default-language: GHC2024`;
- `default-extensions:` carrying the shared baseline, currently `OverloadedStrings`;
- `other-modules`, dependencies, and consumer package/module requirements;
- an `exposed-modules` block for the conformance facade.

Repaste the fragment whole on every regeneration. Hand-merging it is how a build acquires an extension the generator no longer emits, or loses one it started needing. See [specification and scaffolding](spec-and-scaffolding.md) for the other sidecars written beside it.

## Expect module-local pragmas, and only from the closed set

An overwriteable generated module declares any syntax beyond the baseline itself, as a module-local `{-# LANGUAGE #-}` pragma, and only when it actually needs it. The requestable set is closed and checked:

`BlockArguments`, `DeriveAnyClass`, `DuplicateRecordFields`, `OverloadedLabels`, `OverloadedRecordDot`, `QualifiedDo`, `TemplateHaskell`, `TypeFamilies`.

Two consequences for the service package. Do not add these to your package's `default-extensions` on the generated layer's behalf — the module already asks for what it needs, and a package-wide enable hides which modules depend on it. And do not treat a pragma appearing or disappearing between regenerations as noise: it tracks a real change in what the module contains.

## Name the runtime package explicitly

The Cabal package that compiles the generated service runtime is build metadata, and it is **never inferred**. Declare it in the workspace manifest:

```text
runtime-package ticket-service
```

or override it for one run with `keiro-dsl scaffold ... --runtime-package ticket-service`. The name is validated against Cabal's package-name grammar, so a typo fails at planning time rather than at build time. `WorkspaceManifest` carries it as `wmfRuntimePackage` with its source location; the CLI override wins over the manifest when both are present.

## Let the service scaffold one conformance package

A configured service generates **at most one** local conformance package. Its runner imports a single generated `<Generated prefix>.Conformance` facade, which is compiled in the consumer's runtime package rather than duplicated into the test package. That is the whole point of the runtime-package declaration: the facade and the runtime it exercises are the same compiled code.

The conformance ledger records the facade module and runtime package, so a later run can detect that either moved.

Two refusals guard the arrangement:

- `DuplicateConformanceFactKeys` — two conformance facts claim one key, which would make the report ambiguous. Fix the spec; do not rename a key to dodge the collision.
- `ConformancePackageRefusal` — the package plan itself is not constructible, most often because the runtime package is missing or ill-formed.

`ScaffoldReport` carries `reportConformancePackage`. Read it rather than inspecting the filesystem to decide whether a package was written.

## Leave generated imports alone

Generated modules plan their consumer-owned imports once per module: a unique type name gets an explicit unqualified import, while collisions, external values, constructors, generated shapes, and binding APIs get deterministic short qualified aliases. Imports are merged, deduplicated, and sorted.

This is presentation, not semantics — identities and create-once ownership do not move — but it is generated presentation, so do not reformat it. An import block that differs from a fresh scaffold means the file was edited or the generator changed.

Aggregate Haskell types reach consumers through the typed `AggregateHaskellSource` surface (`aggregateConsumerHaskellSource`, `aggregateSourceReferences`, `aggregateSourceStaticImports`, `renderAggregateHaskellSource`). The flattened `aggregateHaskellType` and `aggregateImports` text pair they replaced is gone; tooling that rendered module-qualified strings must move to the typed surface.

## Related Patterns

- [Specification and scaffolding](spec-and-scaffolding.md) covers the scaffold run, the firewall, and the other sidecars.
- [The six-package service standard](service-packages.md) places the runtime and conformance packages in the repository layout.
- [Test layout](test-layout.md) places the generated conformance suite beside hand-written tests.
- [Behavior conformance and obligations](../keiro/behavior-conformance.md) defines what the conformance report proves.
- [Composable service workspaces](../keiro/service-workspaces.md) owns the manifest the `runtime-package` clause lives in.
