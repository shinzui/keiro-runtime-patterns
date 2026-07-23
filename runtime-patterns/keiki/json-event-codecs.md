---
type: Guide
title: "Deriving JSON Codecs for Keiki Event Sums"
description: "Deriving kind-discriminated JSON codecs with keiki-codec-json"
timestamp: 2026-07-22T09:35:21-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-json-event-codecs
tags: [keiki, json-event-codecs]
status: current
---

# Deriving JSON Codecs for Keiki Event Sums

**Generate explicit, versioned private-event codecs and make every schema choice compile-time visible.**

Keiki core is intentionally codec-free; JSON serialization for persisted private events lives in `keiki-codec-json`. Use `deriveEventCodecSkeleton` for sum types whose constructors wrap record payloads so encoding decisions, stable wire kinds, schema versions, and missing-field behavior remain explicit.

## Generate The Complete Codec Surface

For an event sum, invoke the splice with deliberate field settings:

```haskell
import Keiki.Codec.JSON.Event
  ( defaultEventCodecOptions
  , deriveEventCodecSkeleton
  )

$(deriveEventCodecSkeleton defaultEventCodecOptions ''OrderEvent)
```

The splice emits five top-level bindings, using a prefix made by lower-casing the type name's first letter:

```haskell
orderEventToJSON        :: OrderEvent -> Aeson.Value
orderEventFromJSON      :: Aeson.Value -> Either String OrderEvent
orderEventEventTypes    :: [Text]
orderEventKindMap       :: [(Text, Text)]
orderEventSchemaVersion :: Int
```

Use `deriveEventCodecSkeletonAs "myPrefix" opts ''OrderEvent` when the inferred prefix is unsuitable. `EventTypes` contains the resolved wire kinds in declaration order, `KindMap` pairs Haskell constructor names with those kinds, and `SchemaVersion` exposes the encoder's current version.

Every encoded object carries the discriminator key, defaulting to `"kind"`, and the in-band version key, defaulting to `"v"`, alongside its payload fields:

```json
{
  "kind": "OrderPlaced",
  "v": 1,
  "orderId": "order-42"
}
```

When `kindOverrides` names a constructor, the pinned value becomes the wire kind instead of the Haskell constructor name.

## Keep The Anti-Drift Default

Every payload field is handled by its field name in exactly one of three ways:

- `fieldCodecOverrides` selects an author-supplied `FieldCodec`.
- `passthroughFields` uses the field type's `ToJSON` and `FromJSON` instances.
- Every other field is unhandled, and `onMissingCodec` decides whether the splice fails or emits an explicit TODO binding.

`FailAtCompileTime` is the default and should remain the service default. `EmitTodoBindings` is only a staging aid: its generated placeholders compile but throw if evaluated. There is no generic fallback, so adding a payload field forces a visible codec decision.

## Configure All Eight Options Deliberately

`EventCodecOptions` has eight fields:

```haskell
data EventCodecOptions = EventCodecOptions
  { fieldCodecOverrides :: Map String FieldCodec
  , passthroughFields    :: Set String
  , kindFieldName        :: String
  , kindOverrides        :: Map String String
  , versionFieldName     :: String
  , currentVersion       :: Int
  , upcasters            :: [(Int, Name)]
  , onMissingCodec       :: OnMissingCodec
  }
```

Start from `defaultEventCodecOptions`: empty overrides and passthrough fields, `"kind"`, no kind pins, `"v"`, version `1`, no upcasters, and `FailAtCompileTime`.

Pin a wire kind before renaming a persisted constructor. For a structural envelope change, increase `currentVersion` and provide one upcaster for every historical source version. A version-`n` function upgrades one whole JSON object to version `n + 1`; the splice rejects gaps, duplicates, and any chain that is not exactly `[1 .. currentVersion - 1]`.

## Use Missing-Field Defaults Only For Additive Changes

`FieldCodec` now carries a missing-key hook:

```haskell
data FieldCodec = FieldCodec
  { fcEncode    :: Name
  , fcDecode    :: Name
  , fcOnMissing :: Maybe Name
  }

fieldCodec :: Name -> Name -> FieldCodec
```

`fcOnMissing` names a top-level constant of the field's Haskell type. Use it when a field is purely additive and old envelopes should decode with a stable default. The `fieldCodec encodeName decodeName` smart constructor creates the strict form with no missing-key default.

Decoding ignores unknown object keys, so removing a field does not by itself break old envelopes. It can still break replay if that field carried command information needed to reconstruct a transition. Review the emit-every-field rule before deleting persisted data.

The generated decoder calls runtime helpers such as `lookupVersion` and `migrateEnvelope`; application code normally does not call them directly. Upcasting runs before discriminator dispatch, so a migration may change both payload keys and the wire kind.

## Preserve The Package Boundary

`keiki-codec-json` exists so the pure core remains aeson-free. Do not add aeson to aggregate modules merely to hand-write private-event JSON when the skeleton can express the contract. Keep public integration events on separately versioned, bounded-context contracts; these generated codecs are for the private events stored on a service's durable stream.

## Related Patterns

- [Event Schema Evolution](./event-schema-evolution.md) gives the complete additive-field, constructor-rename, and upcaster playbook.
- [Keiki Transducer Best Practices](./transducer-best-practices.md) explains why private event fields are shaped for replay rather than public integration contracts.
- [Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md) lists the fifth generated binding and other migration-visible changes.
