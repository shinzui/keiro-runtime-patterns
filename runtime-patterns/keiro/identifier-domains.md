---
type: Standard
title: "Enforced identifier domains"
description: "The frozen TypeID-v7 admission contract for prefix-bearing IDs under language version 3, and the producer-last rollout its adoption requires"
timestamp: 2026-08-02T19:56:33-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-identifier-domains
tags: [keiro, identifier-domains]
status: current
---

# Enforced identifier domains

**Under [language version 3](language-versions.md) a prefix-bearing ID is a checked domain, not a `Text` field: construct it through the generated `parseX`/`mkX`, and treat adopting the domain as a public-consumer break with a producer-last rollout.**

Version 1 and version 2 generate an ID whose constructor is available and whose text is unvalidated. Version 3 selects `keiro-dsl/runtime-semantics/2` and binds every prefix-bearing ID to the frozen `keiro-dsl/id-domain/typeid-v7/1` contract published as `Keiro.Codec.IdDomain` in `keiro-core` and re-exported from `keiro`, so generated code keeps a single direct `keiro` dependency.

## Know exactly what the contract admits

`typeIdV7Domain <prefix>` yields the `IdDomainContract` every v3 ID is checked against. Admission requires all of:

- canonical lowercase TypeID text, byte-identical to re-rendering the parsed value;
- the declared prefix followed by exactly one `_` separator;
- a 26-character Crockford base32 suffix;
- UUIDv7 version and variant bits;
- a JSON string representation.

`validateIdDomainText` returns the specific `IdDomainFailure` — `IdDomainNonCanonical`, `IdDomainWrongPrefix`, `IdDomainMalformed`, or `IdDomainNotUuidV7`. Branch on the constructor; do not parse the rendered text. `idDomainAcceptsText` is the Boolean shorthand for a predicate, and `idDomainSampleText` supplies a conforming value for fixtures and documentation.

Nothing here is configurable. `enforcedIdDomainVersion` is a frozen string; a future admission policy arrives as a new version identifier and a new language version, never as a change to this one.

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

## Keep history readable and current input strict

Adoption is deliberately asymmetric, and the asymmetry is the whole design:

- **Historical event decoding** keeps an explicitly named internal legacy constructor, so an event stored before adoption still replays.
- **Current command and public decoding** reject that same malformed text, reporting the JSON field path.

Do not "fix" this by loosening current decoding, and do not delete the legacy constructor to tidy the generated module. A stream whose rebuilt state still contains legacy-invalid text stays intentionally uncacheable until it is overwritten or explicitly migrated.

## Roll out an adoption producer-last

Adopting the domain on an existing ID emits `IdDomainContractChanged` from `keiro-dsl diff`, with this compatibility vector:

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

The ID-domain version is persisted in scaffold and workspace records and in `--explain-bindings` output, independently of nominal equality, so a repository can assert which contract each ID is on. Before adoption reaches production:

1. Commit a genuine pre-adoption payload fixture and prove it still replays.
2. Run the targeted replay audit with `--replay-impact-out`.
3. Run the generated [behavior-conformance](behavior-conformance.md) report and confirm the migration keys pass.
4. Deploy consumers, then the producer.

## Related Patterns

- [Keiro DSL language versions](language-versions.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Exact projection domains](../keiki/exact-projection-domains.md)
