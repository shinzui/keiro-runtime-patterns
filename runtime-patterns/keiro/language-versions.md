---
type: Standard
title: "Keiro DSL language versions"
description: "Declaring an explicit language keiro-dsl preamble, adopting the stable version 4 contract, and auditing compatibility-only sources"
timestamp: 2026-08-06T02:47:25Z
generated:
  by: human:nadeem
  at: "2026-08-06T02:47:25Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-language-versions
tags: [keiro, language-versions]
status: current
---

# Keiro DSL language versions

**Declare `language keiro-dsl <version>` as the first significant clause of every `.keiro` source; never rely on the toolchain inferring one.**

The preamble selects a frozen released grammar before the body is parsed. It is the mechanism that lets keiro-dsl add syntax without changing what an existing committed source means, so treat the declaration as part of the contract rather than as boilerplate.

## Declare the version before the context

```text
language keiro-dsl 4
context hospital-capacity
```

The clause must be the first significant clause; comments and blank lines may precede it. Exactly one may appear. A version is a positive decimal — `0` is not a version. Every skeleton printed by `keiro-dsl new <kind>` declares the current stable version.

Failures at this boundary are reported before any body grammar runs, with their own stable codes: `InvalidLanguageVersion`, `UnsupportedLanguageVersion`, `DuplicateLanguagePreamble`, `MisplacedLanguagePreamble`, and `LanguageFeatureRequiresVersion`. Branch automation on the code, not on the rendered sentence.

## Author every new source at version 4

Version 4 is the sole stable authoring contract. Versions 1 through 3 are `compatibility-only`: they keep their released semantics forever and are never silently upgraded, but they are not where new work belongs.

| Version | Syntax profile | Runtime semantics | Support | Admits |
|---|---|---|---|---|
| 1 | `keiro-dsl/syntax-profile/1` | `keiro-dsl/runtime-semantics/1` | compatibility-only | The frozen released grammar as of Keiro 0.6.0.0. Aggregate transitions keep the create-once whole-transducer hole. |
| 2 | `keiro-dsl/syntax-profile/2` | `keiro-dsl/runtime-semantics/1` | compatibility-only | Everything in version 1, plus [consumer-owned nominal bindings](nominal-bindings.md) and [authoritative typed scalar aggregate expressions](aggregate-expressions.md) with explicit per-transition ownership. |
| 3 | `keiro-dsl/syntax-profile/2` | `keiro-dsl/runtime-semantics/2` | compatibility-only | Version 2's grammar exactly, with every prefix-bearing ID moved onto the enforced [TypeID-v7 identifier domain](identifier-domains.md) and made abstract in generated code. |
| 4 | `keiro-dsl/syntax-profile/3` | `keiro-dsl/runtime-semantics/3` | **stable** | Version 3's semantics plus field aliases, contract-level TypeID admission, and strict spec-surface validation. |

Version 3 remains the clearest case that syntax and runtime behavior are separate axes: it admits exactly the same grammar as version 2 and still changes what the runtime accepts. Read the two identifiers, not the version number.

A source that uses syntax its profile does not admit fails with `LanguageFeatureRequiresVersion` at the language boundary. A well-formed but unsupported future version fails with `UnsupportedLanguageVersion` before its body is read, so a newer file never produces a misleading body-grammar error.

## Know what version 4 adds

Syntax profile 3 adds exactly one grammar feature over profile 2 — `FieldAliasSyntax`, the independent `haskell <selector>` and `as "<wire-key>"` declarations on direct aggregate and integration-contract fields. Everything else version 4 changes is runtime semantics.

Runtime semantics 3 adds two capabilities to semantics 2's TypeID-v7 generated IDs and nominal equality:

- **`ContractIdDomainTypeIdV7`** extends the frozen TypeID-v7 admission policy to public contract fields declared `typeid "<prefix>"`, which scaffold as `KindID "<prefix>"`. See [enforced identifier domains](identifier-domains.md).
- **`StrictSpecSurfaceValidation`** closes accepted-but-unenforced surfaces: numeric floors, duplicate and shadowing rules, stable runtime-identity uniqueness, Kafka and PostgreSQL naming, intake envelope and schema coupling, contract topic aliases, and the aggregate wire convention. Values that cannot lower to working generated code are rejected under *every* version; these additional rules apply only at version 4.

Version 4 also resolves every internally decidable process, router, projection, publisher, queue, pgmq source-key, read-model identity, and timer-ID reference, and rejects duration values that cannot fit the runtime `Int` seconds representation. Sources that previously scaffolded broken code now fail during `check`.

## Expect a stderr notice on a compatibility-only source

`check`, `scaffold`, and the working-tree side of `diff` write one stderr line for any source whose effective contract is not stable, naming the effective version, the source form, the support level, the runtime-semantics identity, and the fact that language-4 strict spec-surface validation is not being applied. A stable source stays silent, so adopting version 4 removes the noise rather than adding it.

The line goes to stderr, not stdout, and it is not a diagnostic. Automation that asserts on exact stderr must be updated; automation that reads diagnostics is unaffected.

## Enforce a version floor in CI

`keiro-dsl check INPUT --min-language N` fails any source or workspace whose *effective* version is below `N`, with the stable code `LanguageVersionBelowMinimum`. Set the floor to the version your service has actually adopted so a source cannot silently regress, and raise it as part of the adoption change rather than afterwards.

```bash
keiro-dsl check domain/service.keiro --min-language 4
```

`DiagnosticCode` now derives `Ord`, `Enum`, and `Bounded`, so tooling can enumerate the full code set rather than hardcoding a list.

## Query the registry instead of hardcoding version numbers

From Keiro 0.8 every registry entry selects an immutable `SyntaxProfile` and a runtime-semantics identity explicitly; nothing is inherited from numeric ordering, so version 3 reusing version 2's profile is a stated fact rather than an accident of arithmetic. Tooling must read the registry:

- `currentStableLanguageVersion` for the version new sources must declare, and `languageSupportForVersion` for whether a given version is `Stable` or `CompatibilityOnly`;
- `syntaxProfileIdentifier` and `syntaxProfileSupportsFeature` for what a profile admits;
- `languageVersionsSupportingFeature` for every version that owns a `LanguageFeature`, and `languageFeatureMinimumVersion` for the first;
- `languageSupportsFeature` for the direct question about one version;
- `sourceLanguageDiagnosticMessage` for the message behind a `SourceLanguageErrorCode`.

Never write `4` into tooling. The registry holds exactly one stable version and enforces that invariant; read it and the number follows the toolchain.

`LanguageDefinition` is exported with all its fields, which makes positional construction and non-wildcard record patterns fail to compile — match with a wildcard. `definitionBodyParser` survives only as a compatibility projection and no longer drives parser dispatch; never branch on it.

## Carry the checked contract, not a bare `Spec`

The semantic input downstream of parsing is `CheckedService` — a normalized graph paired with the `EffectiveLanguageContract` it was checked under. The CLI retains it through validation, scaffold and harness planning, fold fingerprints, diff, replay-impact analysis, inspection JSON, and sidecar ledger rows.

Since Keiro 0.9 there is no alternative. The misleading `Spec`-only wrappers — `aggregateFoldFingerprint`, `aggregateFoldSurface`, `diffSpecs`, `replayImpact`, `nominalEqualityContract`, `nominalEqualityIdentity`, and `nominalEqualityIdentities` — are removed. Retain a `CheckedService` and pass it to the service-taking functions:

```haskell
aggregateFoldFingerprintForService :: CheckedService -> Aggregate -> Either FoldSurfaceError Text
diffServices    :: CheckedService -> CheckedService -> Either FoldSurfaceError [Change]
replayImpactServices :: CheckedService -> CheckedService -> Either FoldSurfaceError ReplayImpact
```

`legacyCheckedService` still exists for a genuinely version-1 source, but constructing one is now an explicit assertion that the version-1 contract applies. Do not reach for it to satisfy a type.

These APIs return `Either FoldSurfaceError` rather than throwing or silently producing a wrong fingerprint. `FoldSurfaceError` names which part of the surface failed to resolve — type graph, nominal, register type, register initial, guard, or event output — and `renderFoldSurfaceError` gives the message. Scaffold planning refuses the same error before generating any module, so a resolution failure can no longer reach generated code.

Grammar-only differences between versions 1 and 2 preserve generated and fold bytes because both select `runtime-semantics/1`; a contract that changes runtime behavior contributes its own fingerprint discriminator through `runtimeSemanticsFingerprintSegment`.

Fold fingerprints themselves widened in 0.9 from 16-hex-digit FNV-1a-64 to 32-hex-digit FNV-1a-128, deliberately invalidating every snapshot discriminated by the earlier value. Read [evolution gates and rollout ordering](evolution-and-rollout.md) before upgrading a service with live snapshots.

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
6. Raise `--min-language` in CI to the version you just adopted, in the same change.

The tool never upgrades a file for you, and it never translates hand-owned behavior. Automated sequential upgrades and fleet-wide rewriting are deferred upstream; plan a version move as manual work.

## Read the declaration change as its own diff class

Adding or changing the preamble alone is reported as `SourceLanguageDeclarationChanged` with an all-compatible six-surface vector and a no-semantic-action remedy: generated bytes, fold fingerprints, and replay impact are unchanged by the declaration itself. Any *behavior* difference travels under its own findings, so do not read a compatible source-language finding as clearance for the version-2 features it unlocks.

Sidecar ledgers carry additive source-language rows. A ledger written before this contract has no such row and is interpreted as legacy, so an old ledger does not force a spurious rescaffold.

## Related Patterns

- [Keiro-dsl adoption](dsl-adoption.md)
- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Enforced identifier domains](identifier-domains.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Composable service workspaces](service-workspaces.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Specification and scaffolding](../architecture/spec-and-scaffolding.md)
