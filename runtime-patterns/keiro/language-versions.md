---
type: Standard
title: "Keiro DSL language versions"
description: "Declaring an explicit language keiro-dsl preamble, choosing among versions 1 through 3, and auditing legacy-unversioned sources"
timestamp: 2026-08-02T19:56:33-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-language-versions
tags: [keiro, language-versions]
status: current
---

# Keiro DSL language versions

**Declare `language keiro-dsl <version>` as the first significant clause of every `.keiro` source; never rely on the toolchain inferring one.**

The preamble selects a frozen released grammar before the body is parsed. It is the mechanism that lets keiro-dsl add syntax without changing what an existing committed source means, so treat the declaration as part of the contract rather than as boilerplate.

## Declare the version before the context

```text
language keiro-dsl 1
context hospital-capacity
```

The clause must be the first significant clause; comments and blank lines may precede it. Exactly one may appear. A version is a positive decimal — `0` is not a version. Every skeleton printed by `keiro-dsl new <kind>` already declares version 1.

Failures at this boundary are reported before any body grammar runs, with their own stable codes: `InvalidLanguageVersion`, `UnsupportedLanguageVersion`, `DuplicateLanguagePreamble`, `MisplacedLanguagePreamble`, and `LanguageFeatureRequiresVersion`. Branch automation on the code, not on the rendered sentence.

## Choose the version by the syntax the service actually needs

| Version | Syntax profile | Runtime semantics | Admits |
|---|---|---|---|
| 1 | `keiro-dsl/syntax-profile/1` | `keiro-dsl/runtime-semantics/1` | The frozen released grammar as of Keiro 0.6.0.0. Aggregate transitions keep the create-once whole-transducer hole. |
| 2 | `keiro-dsl/syntax-profile/2` | `keiro-dsl/runtime-semantics/1` | Everything in version 1, plus [consumer-owned nominal bindings](nominal-bindings.md) and [authoritative typed scalar aggregate expressions](aggregate-expressions.md) with explicit per-transition ownership. |
| 3 | `keiro-dsl/syntax-profile/2` | `keiro-dsl/runtime-semantics/2` | Version 2's grammar exactly, with every prefix-bearing ID moved onto the enforced [TypeID-v7 identifier domain](identifier-domains.md) and made abstract in generated code. |

Stay on version 1 when the service needs neither the version-2 grammar nor the enforced ID domain. Version 1 is not deprecated, and moving a source across any version changes generated output — it is a scaffolding change, not a formatting one.

Version 3 is the clearest case that syntax and runtime behavior are separate axes: it admits exactly the same grammar as version 2 and still changes what the runtime accepts. Read the two identifiers, not the version number.

A version-1 or legacy source that uses version-2 syntax fails with `LanguageFeatureRequiresVersion` at the language boundary. A well-formed but unsupported future version fails with `UnsupportedLanguageVersion` before its body is read, so a newer file never produces a misleading body-grammar error.

## Query the registry instead of hardcoding version numbers

From Keiro 0.8 every registry entry selects an immutable `SyntaxProfile` and a runtime-semantics identity explicitly; nothing is inherited from numeric ordering, so version 3 reusing version 2's profile is a stated fact rather than an accident of arithmetic. Tooling must read the registry:

- `syntaxProfileIdentifier` and `syntaxProfileSupportsFeature` for what a profile admits;
- `languageVersionsSupportingFeature` for every version that owns a `LanguageFeature`, and `languageFeatureMinimumVersion` for the first;
- `languageSupportsFeature` for the direct question about one version;
- `sourceLanguageDiagnosticMessage` for the message behind a `SourceLanguageErrorCode`.

`LanguageDefinition` is exported with all its fields, which makes positional construction and non-wildcard record patterns fail to compile — match with a wildcard. `definitionBodyParser` survives only as a compatibility projection and no longer drives parser dispatch; never branch on it.

## Carry the checked contract, not a bare `Spec`

The semantic input downstream of parsing is `CheckedService` — a normalized graph paired with the `EffectiveLanguageContract` it was checked under. The CLI retains it through validation, scaffold and harness planning, fold fingerprints, diff, replay-impact analysis, inspection JSON, and scaffold-record rows.

Use it in any tooling built on `keiro-dsl`. The `Spec`-only entry points are explicit legacy/version-1 compatibility wrappers around `legacyCheckedService`; calling one silently asserts the version-1 contract, which is wrong for a version-3 source. Grammar-only differences between versions 1 and 2 preserve generated and fold bytes because both select `runtime-semantics/1`; a contract that changes runtime behavior contributes its own fingerprint discriminator through `runtimeSemanticsFingerprintSegment`.

## Reach for the located frontend only for source tooling

Keiro 0.8 publishes `Keiro.Dsl.Source`, `Keiro.Dsl.Syntax`, and `Keiro.Dsl.Frontend` as an advanced API: an ordered, located `SurfaceSource` with exact half-open spans and structured failures carrying a phase (source selection, body parsing, lowering), a stable code, a primary span, a message, expected items, and supported-version metadata. Megaparsec types stay internal.

This is for editors, linters, and diagnostics renderers. Ordinary services keep using `parseSource`, `parseSpec`, and `parseSpecText`, whose behavior and rendered diagnostics are unchanged. Canonical pretty printing remains non-lossless — the located layer retains neither comments nor whitespace — so do not build a formatter that promises to preserve them.

## Treat an undeclared source as legacy, and audit it

A source with no preamble stays readable as `legacy-unversioned` and selects effective version 1. That is a compatibility bridge, not a state to leave a repository in. `parse` and `pretty` preserve the distinction: neither one silently writes a `language` clause into a file that lacked it.

Audit which form each source is in:

```bash
keiro-dsl inspect domain/service.keiro --format=json
keiro-dsl inspect domain/service.keiro-workspace --format=json
```

The report gives `sourceForm` (`legacy-unversioned` or `declared`), the declared version if any, and the effective version. Workspace inspection reports the same provenance for every member in canonical path order. Make "every member is `declared`" a repository assertion.

## Keep one effective version across a workspace

Workspace composition compares member effective versions **before** merging the semantic graph. Members that disagree fail with `WorkspaceLanguageVersionMismatch`; one semantic graph cannot combine two language contracts. Move the whole workspace across a version in a single change.

## Adopt a version deliberately

1. Change the preamble in the owning source, or in every member of a workspace at once.
2. Canonicalize with `keiro-dsl pretty`, the explicit alias for canonical parse-and-render.
3. Run `keiro-dsl check INPUT --explain-bindings` and resolve every new obligation.
4. Re-scaffold and run the generated compiled harness.
5. Run `keiro-dsl diff INPUT --since <ref>` and read the source-language finding.

The tool never upgrades a file for you, and it never translates hand-owned behavior. Automated sequential upgrades and fleet-wide rewriting are deferred upstream; plan a version move as manual work.

## Read the declaration change as its own diff class

Adding or changing the preamble alone is reported as `SourceLanguageDeclarationChanged` with an all-compatible six-surface vector and a no-semantic-action remedy: generated bytes, fold fingerprints, and replay impact are unchanged by the declaration itself. Any *behavior* difference travels under its own findings, so do not read a compatible source-language finding as clearance for the version-2 features it unlocks.

Scaffold and workspace records carry additive source-language rows. A record written before this contract has no such row and is interpreted as legacy, so an old record does not force a spurious rescaffold.

## Related Patterns

- [Keiro-dsl adoption](dsl-adoption.md)
- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Enforced identifier domains](identifier-domains.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Composable service workspaces](service-workspaces.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Specification and scaffolding](../architecture/spec-and-scaffolding.md)
