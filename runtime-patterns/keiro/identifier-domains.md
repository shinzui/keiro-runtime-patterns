---
type: Standard
title: "Enforced identifier domains"
description: "Apply the TypeID default through the frozen v7 admission contract for aggregate IDs and public contract fields, with the rollout each surface requires"
timestamp: 2026-09-21T20:25:00Z
generated:
  by: process:codex
  at: "2026-09-21T20:25:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-identifier-domains
tags: [keiro, identifier-domains]
status: current
---

# Enforced identifier domains

**Every service-owned ID is TypeID-backed by default, and a prefix-bearing ID is a checked domain rather than a `Text` field: construct it through the generated `parseX`/`mkX`, and treat adoption as a public-consumer break whose rollout direction depends on the surface.**

The fleet-wide modeling rule is [domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md). It also requires nominal wrappers for non-ID domain scalars and names the narrow exceptions for external identifiers and natural locators. This standard defines the stricter Keiro admission and migration contract once a declaration is an ID; it is not permission to model an application ID as raw text outside the DSL.

Version 1 and version 2 generate an ID whose constructor is available and whose text is unvalidated. Version 3 selects `keiro-dsl/runtime-semantics/2` and binds every prefix-bearing *aggregate* ID to the frozen `keiro-dsl/id-domain/typeid-v7/1` contract published as `Keiro.Codec.IdDomain` in `keiro-core` and re-exported from `keiro`, so generated code keeps a single direct `keiro` dependency. [Version 4](language-versions.md) extends the same frozen contract to public *integration-contract* fields.

The two adoptions roll out in opposite directions. Do not carry the version-3 habit onto a version-4 contract field.

## Know exactly what the contract admits

`typeIdV7Domain <prefix>` yields the `IdDomainContract` every v3 ID is checked against. Admission requires all of:

- canonical lowercase TypeID text, byte-identical to re-rendering the parsed value;
- the declared prefix followed by exactly one `_` separator;
- a 26-character Crockford base32 suffix;
- UUIDv7 version and variant bits;
- a JSON string representation.

`validateIdDomainText` returns the specific `IdDomainFailure` — `IdDomainNonCanonical`, `IdDomainWrongPrefix`, `IdDomainMalformed`, or `IdDomainNotUuidV7`. Branch on the constructor; do not parse the rendered text. `idDomainAcceptsText` is the Boolean shorthand for a predicate, and `idDomainSampleText` supplies a conforming value for fixtures and documentation.

The v7 policy is frozen. Keiro 0.18.0.0 adds an explicit alternative under Language 6; omitting `domain` preserves the original v7 policy and identity.

## Admit retained UUIDv5 identities explicitly

Declare `id RetainedId prefix=retained domain=typeid-v5-or-v7` when the domain must accept canonical TypeIDs backed by UUIDv5 as well as UUIDv7. Use the same declaration, optionally with a total consumer binding, in direct fields, structural leaves, ID-keyed maps, queues, query types, router identities, and declared public-contract fields. Do not maintain an opaque ID twin for this case.

The frozen runtime constructor is `typeIdV5OrV7Domain`; its identity is `keiro-dsl/id-domain/typeid-v5-or-v7/1`. It still enforces canonical lowercase text, prefix, and RFC UUID variant. `IdDomainContract` now carries `IdAdmission`, and failures include `IdDomainVersionNotAdmitted` and `IdDomainVariantNotRfc4122`; extend exhaustive matches. This selects admission only: preserve ID generators, deterministic seeds, namespaces, stream names, and stored identities.

Read `IdDomainContractChanged` by direction. Widening v7 to v5-or-v7 makes new UUIDv5 writes unreadable by old v7 readers; deploy readers before writers. Narrowing back can reject retained UUIDv5 history; retain a historical reader and prove the affected histories before cutover. Both directions change affected fold/replay identity. The older language-3 adoption vector below is not a universal vector for this new change.

The declaration must also choose a human-readable prefix. Admission rules answer whether a value is valid; they do not make an abbreviated prefix intelligible. Follow [TypeID prefix naming](typeid-prefix-naming.md): use the full ubiquitous-language noun by default and treat a later prefix rename as a durable migration.

## Construct IDs through the generated abstract API

Version 3 makes each generated prefix-bearing ID abstract. Import `parseX`, `mkX`, and `xText` from the context-level `Generated.<Context>.Nominals` module. The raw constructor and `unsafeXFromLegacyText` exist only in the generated internal replay module, and hand-owned code must not reach for them.

```haskell
import Generated.OrderBook.Nominals (OrderId, orderIdText, parseOrderId)

-- CORRECT: admission failure is a value.
case parseOrderId rawText of
  Right orderId -> accept orderId
  Left failure  -> rejectWithDomainFailure failure

-- WRONG: the raw constructor is internal on purpose; it is a replay seam,
-- not a fast path for trusted input.
```

Validation happens before binding conversion, before current JSON decoding, in literals, and in scaffold samples — so a malformed ID cannot enter the model through any current surface. For a [consumer-owned nominal binding](nominal-bindings.md), the generated harness additionally probes exact projection, fixture-domain membership, distinct representations, wrong prefixes, and normalization.

## Declare a contract field `typeid` and let it scaffold as `KindID`

From version 4, a public contract field declared `typeid "<prefix>"` scaffolds as `KindID "<prefix>"` — the prefix is reflected in the type, so a decoder cannot silently widen it. Keiro's admission policy runs *before* the prefix-indexed value is constructed:

```haskell
parseKindIdV7Text  :: ValidPrefix prefix => Text  -> Either IdDomainFailure (KindID prefix)
parseKindIdV7Value :: ValidPrefix prefix => Value -> Parser (KindID prefix)
```

Generated decoders use `parseKindIdV7Value` with `explicitParseField`, so Aeson attaches the owning JSON field key to the same stable `IdDomainFailure` set. A rejection therefore names both the field path and which admission rule failed. Do not hand-write a `FromJSON` that bypasses these; a plain `KindID` parse skips the canonical-form and UUIDv7 checks.

## Name a declared ID on a contract field under version 6

[Language 6](language-versions.md) lets a contract event field name a top-level `id` declaration — `templateId: TemplateId` — instead of repeating `typeid "template"`. The generated or consumer-bound domain type keeps that declaration's selected admission domain and compatibility identity, so the public field cannot drift from the prefix the aggregate owns. Only `id` declarations are accepted; enums, nominal scalars, and mapped declarations are rejected. Use Language 6 from Keiro 0.17.0.0 onward; the older `typeid` spelling remains valid.

Moving between `typeid "template"` and `TemplateId` with the same prefix preserves JSON bytes but changes the Haskell type, so consumers must rebuild. A prefix change remains a breaking public-contract change.

The same candidate admits declared IDs as structural leaves and as `Map[DeclaredId] T` keys; see [mapped consumer surfaces](mapped-consumer-surfaces.md). A direct `Optional DeclaredId` command or event field is still rejected. In Keiro 0.18.0.0, use a named `mapped structural value` with `wire Optional DeclaredId` to preserve bare optional JSON; use a one-field structural record only when an object wrapper is the intended wire shape.

## Roll a contract-field adoption producer-first, and drain

Moving an unchanged contract field from version 3 to version 4 emits `ContractTypeIdDomainChanged`, whose vector is **not** the aggregate one:

| Surface | Verdict |
|---|---|
| `private-history-read` | not applicable |
| `old-binary-read-new-events` | not applicable |
| `snapshot-hydration` | not applicable |
| `public-consumer` | **breaking** |
| `persisted-identity` | not applicable |
| `consumer-build` | **breaking** |
| rollout | **producer-first** and **drain-required** |

Producer-first is the reverse of the aggregate-ID adoption below, because the tightening lands on what this service *emits* rather than on what it accepts. Drain-required means in-flight messages written under the looser contract must clear before consumers move; a consumer deployed early will reject traffic that is still legitimately in the queue.

## Keep history readable and current input strict

Adoption is deliberately asymmetric, and the asymmetry is the whole design:

- **Historical event decoding** keeps an explicitly named internal legacy constructor, so an event stored before adoption still replays.
- **Current command and public decoding** reject that same malformed text, reporting the JSON field path.

Do not "fix" this by loosening current decoding, and do not delete the legacy constructor to tidy the generated module. A stream whose rebuilt state still contains legacy-invalid text stays intentionally uncacheable until it is overwritten or explicitly migrated.

## Roll out an aggregate-ID adoption producer-last

Adopting the domain on an existing aggregate ID emits `IdDomainContractChanged` from `keiro-dsl diff`, with this compatibility vector:

| Surface | Verdict |
|---|---|
| `private-history-read` | compatible — old events still replay |
| `old-binary-read-new-events` | compatible |
| `snapshot-hydration` | advisory — old snapshots miss and rebuild from events |
| `public-consumer` | **breaking** — external readers see a tightened contract |
| `persisted-identity` | compatible — wire bytes and nominal identity do not move |
| `consumer-build` | advisory |
| rollout | **producer-last** |

Producer-last is not a suggestion: deploy every consumer that must accept the tightened form before the producer starts emitting under it. Discharge the snapshot advisory by expecting a cache miss and a full rebuild, not by hand-editing snapshots. See [evolution gates and rollout ordering](evolution-and-rollout.md).

## Prove the migration before it ships

The ID-domain version is persisted in the sidecar ledgers and in `--explain-bindings` output, independently of nominal equality, so a repository can assert which contract each ID is on. Before adoption reaches production:

1. Commit a genuine pre-adoption payload fixture and prove it still replays.
2. Run the targeted replay audit with `--replay-impact-out`.
3. Run the generated [behavior-conformance](behavior-conformance.md) report and confirm the migration keys pass.
4. Deploy consumers, then the producer.

## Related Patterns

- [Keiro DSL language versions](language-versions.md)
- [Domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md)
- [TypeID prefix naming](typeid-prefix-naming.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Exact projection domains](../keiki/exact-projection-domains.md)
