---
type: Gotcha
title: "Settei Gotchas"
description: "Settei footgun catalogue: null presence, positional precedence, pinning, redaction edges"
timestamp: 2026-07-22T13:36:35-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/config-settei-gotchas
tags: [config, settei-gotchas]
status: current
---

# Settei Gotchas

**Treat these behaviors as invariants when reviewing source assembly, diagnostics, and Kubernetes delivery.**

This catalogue applies to settei 0.2.0.0 services and CLIs. Each trap states the symptom and the fleet rule.

## Null Is Present Input

A higher-precedence source containing `null` wins and passes `RawNull` to the setting decoder. It does not mean “consult a lower source,” so the usual symptom is a decode error shadowing a valid lower value. Delete the key to make it absent; do not assign null to request fallback.

## A Malformed Winner Does Not Fall Back

Resolution decodes the rightmost candidate exactly once. An invalid environment value therefore fails even when a file contains a valid value, and the report shows that file value as shadowed. Fix or remove the winning source; never add error recovery that silently downgrades precedence.

## Precedence Is Only List Position

`Source` has no priority field. Reordering the `[Source]` passed to `resolve` changes behavior without a type error. Build the list in one named function per binary, comment its low-to-high order, and test a repeated key across all layers.

## Kubernetes Metadata Is Not Attestation

Annotations such as `kubernetes.object-kind`, object name, namespace, and file modification time record what the caller supplied while constructing a source. Settei performs no cluster lookup. Use them for diagnosis, never as proof that a value came from an authentic Secret object.

## `Settei.Prelude` Is Internal

The module remains exposed so packages in the settei family can share vocabulary, but it is outside the PVP-stable adoption surface. Application code imports documented modules such as `Settei`, `Settei.Env`, `Settei.Formats`, and `Settei.Kubernetes` directly.

## Upgrade the Package Family in Lockstep

Released settei adapters pin the core family exactly; mixed family versions are unsupported. If the solver reports an exact-bound conflict, update all settei packages together instead of relaxing one adapter's bound. The verified current family release is 0.2.0.0.

## The 0.2.0.0 Formats Umbrella Does Not Fit the GHC 9.12 Cohort

`settei-formats-0.2.0.0` always pulls `settei-dhall-0.2.0.0`, which pins `dhall-json-1.7.12`. That released `dhall-json` requires `bytestring <0.12`, while GHC 9.12.4 supplies `bytestring-0.12.2.0` and the released Settei YAML and Kubernetes adapters require `bytestring >=0.12`. The result is an unsatisfiable dependency graph, not permission to relax a bound.

Services and single-format CLIs in this cohort depend directly on the adapter they use, normally `settei-yaml-0.2.0.0`. Reconsider `settei-formats` only after its complete released dependency graph solves against the fleet compiler and index-state.

## Mounted Files Strip One Newline

`readMountedDirectorySource` strips exactly one trailing line-feed by default, matching ordinary Kubernetes Secret files. It does not trim arbitrary whitespace. Use `keepTrailingNewline` for byte-faithful material and see [Kubernetes Deployment Standard](./kubernetes-deployment.md) for the mounted-directory rules.

## A Missing Bound File Is Absence

A filename declared by `fileBindings` but absent from the projected directory contributes no candidate. A present empty file contributes an empty value. Required settings distinguish them: absence produces a missing-required error, while an empty value reaches the decoder.

## Dhall Import Attribution Stops at the Document

`NoImports` is the safe default. `LocalImportsWithin` permits only a named local root, but Dhall normalization does not preserve leaf-level provenance for every imported field. The report attributes the resolved tree to the loaded Dhall source; do not promise per-import-file provenance.

## Related Patterns

- [Settei Service Configuration Standard](./settei-service-standard.md) defines source ordering and redaction.
- [Settei CLI Configuration Standard](./settei-cli-standard.md) defines repeated file and override semantics.
- [Kubernetes Deployment Standard](./kubernetes-deployment.md) defines mounted-directory and rollout behavior.
