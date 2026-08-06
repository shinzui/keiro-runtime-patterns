---
type: Guide
title: "Event Schema Evolution"
description: "Evolving persisted event JSON with in-band versions, pinned kinds, and upcaster chains"
timestamp: 2026-07-23T23:55:16Z
generated:
  by: human:nadeem
  at: "2026-07-23T23:55:16Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-event-schema-evolution
tags: [keiki, event-schema-evolution]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-23T23:55:16Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; verified exported symbols, signatures, version claims, and links.
---

# Event Schema Evolution

**Evolve persisted private-event JSON without changing the meaning of bytes already stored.**

`keiki-codec-json` separates three kinds of change: additive fields use a missing-key default, Haskell constructor renames pin their historical wire kind, and structural envelope changes advance an in-band schema version through a complete upcaster chain. Choose exactly the move that matches the compatibility problem.

## Own One Version Signal

Every object encoded by `deriveEventCodecSkeleton` carries `versionFieldName`, defaulting to `"v"`, stamped with `currentVersion`. An object with no version key is read as version `1` so pre-versioning events remain decodable.

```json
{
  "kind": "Placed",
  "v": 1,
  "orderId": "order-42",
  "quantity": 3
}
```

If the event store already owns an outer schema-version field, keep this codec at `currentVersion = 1` and evolve at that outer boundary. Two independent version numbers for one payload can disagree without either layer detecting the other's mistake.

## Add A Field With A Missing-Key Default

Purely additive fields do not need a version bump. A syntactic `Maybe a` passthrough decodes an absent key as `Nothing`. A required field needs a named top-level constant through `fcOnMissing`.

```haskell
-- Before: priority did not exist in stored version-1 objects.

defaultPriority :: Priority
defaultPriority = NormalPriority

priorityCodec :: FieldCodec
priorityCodec =
  (fieldCodec 'priorityToJSON 'priorityFromJSON)
    { fcOnMissing = Just 'defaultPriority }

-- After: old objects decode with NormalPriority; currentVersion stays 1.
codecOptions =
  defaultEventCodecOptions
    { fieldCodecOverrides =
        Map.fromList [("priority", priorityCodec)]
    }
```

The default must preserve the historical meaning of an absent field. Do not use an arbitrary zero merely to make decoding succeed.

## Pin A Constructor's Historical Wire Kind

By default the Haskell constructor name is the stored `"kind"`. Pin persisted sums from day one, and always pin a renamed constructor to its previous wire value.

```haskell
-- Before: constructor Placed was stored as {"kind":"Placed", ...}.

-- After: Haskell name changes, stored bytes do not.
codecOptions =
  defaultEventCodecOptions
    { kindOverrides =
        Map.fromList [("OrderPlaced", "Placed")]
    }
```

Override keys are current Haskell constructor base names. The splice rejects unknown keys and duplicate resolved wire kinds. Encoding, decoding, the generated `EventTypes`, and the generated `KindMap` all use the pinned wire value.

## Upcast A Structural Change One Version At A Time

When fields are renamed, nested differently, or change representation, bump `currentVersion` and provide one whole-envelope migration for each historical step. A version-`n` function upgrades one `Aeson.Value` object to version `n + 1` shape.

```haskell
-- Before: version 1 stored the field as "qty".
upcastOrderV1 :: Aeson.Value -> Either String Aeson.Value
upcastOrderV1 value = case value of
  Aeson.Object object ->
    case KeyMap.lookup (Key.fromString "qty") object of
      Nothing -> Left "missing qty"
      Just quantityValue ->
        Right
          (Aeson.Object
            (KeyMap.insert (Key.fromString "quantity") quantityValue object))
  _ -> Left "expected an object"

-- After: the current decoder expects "quantity" at version 2.
codecOptions =
  defaultEventCodecOptions
    { currentVersion = 2
    , upcasters = [(1, 'upcastOrderV1)]
    }
```

For `currentVersion = n`, the splice requires the source versions to be exactly `[1 .. n - 1]`. Gaps, duplicates, zero, and out-of-range rungs fail at compile time. The generated decoder looks up the stored version, runs every required rung in order, then dispatches on the migrated kind and decodes current payload fields. Application code normally does not call `lookupVersion` or `migrateEnvelope` directly.

A chain defect that survives compilation is now caught at the runtime boundary too: keiro's validated event-stream construction rejects a codec whose schema version, event tags, or upcaster chain fail `mkCodec`. Restore the missing rung or deduplicate the conflicting sources rather than reaching for the unchecked constructor.

When several event kinds bump at the same source version, they lower into one rung that dispatches by event type and passes unrelated kinds through byte-for-byte. One kind's upcaster can no longer rewrite another kind's payload at the same version.

An upcaster maps one envelope to one envelope. Splitting one historical event into several current events belongs in the application's event-store adapter, where ordering and write-back policy can be explicit.

## Removing A Field Still Requires Replay Review

Event decoding ignores unknown object keys, so a current payload may omit a field that remains in historical objects. That is decode-compatible, but not automatically replay-safe. If a transition guard or register update consumed the removed value, the private event still needs to expose it for inversion. Check the transducer's emit-every-field rule and replay round trips before deleting persisted data.

## Retire An Event In Two Stages

Deleting the transition that emitted an event breaks hydration for every stream that still contains it. Decode compatibility is irrelevant here: the event decodes fine and then has no inverting edge.

The sanctioned shape is a **replay-only** transition — an edge never taken by forward stepping, retained so historical events stay invertible and keep a defined fold. Retirement is therefore two-stage: first mark the event `retiring` while its live emitting transition stays, then at cutover mark it `deprecated` and change that transition to `replay-only`.

Keep the replay-only edge until every affected stream is terminal, truncated, or has passed a real-log replay audit. Deleting it earlier recreates exactly the break it fixed. This supersedes the older guarded-but-inert pattern for retained edges.

## Verify Every Evolution Against Historical Bytes

Keep literal pre-change JSON fixtures. For additive changes, prove an old object decodes with the intended default. For a constructor rename, prove the encoder still emits the old wire kind and the decoder accepts it. For an upcaster, prove each historical version reaches the current type and that a future version is rejected rather than guessed.

Capture goldens in the same change that bumps the version, while the old shape is still recoverable from the previous specification. A decode golden proves decode compatibility **only** — never describe it as proof that an old event still inverts or folds identically. That question belongs to the replay audit.

## Related Patterns

- [Deriving JSON Codecs](./json-event-codecs.md) documents the complete generated surface and all eight options.
- [Keiki Transducer Best Practices](./transducer-best-practices.md) distinguishes replay-oriented private events from public integration contracts.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) explains why removing a replay-critical field is unsafe even when JSON decoding succeeds.
- [Evolution gates and rollout ordering](../keiro/evolution-and-rollout.md) places these checks in the full gate ladder and rollout sequence.
- [Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md) calls out the codec changes that affect existing code.
