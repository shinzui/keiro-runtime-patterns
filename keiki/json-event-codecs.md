# Deriving JSON Codecs for Keiki Event Sums

Keiki core is intentionally codec-free — the pure layer talks only typed Haskell values. JSON
serialization for the events you persist lives in the sibling package **`keiki-codec-json`**.
This guide covers `deriveEventCodecSkeleton`, which generates a `kind`-discriminated
encode/decode pair for an event sum type, eliminating the hand-written aeson per event and the
drift risk between the Keiki payload shape and the stored JSON.

> This is for the **private event sum** you store on the durable stream. Keep public
> integration messages on their own hand-managed contracts — see "Keep Private Events
> Replay-Oriented" in [transducer-best-practices.md](./transducer-best-practices.md).

## What the splice generates

For an event sum (each constructor a single record payload):

```haskell
import Keiki.Codec.JSON.Event (deriveEventCodecSkeleton, defaultEventCodecOptions)

$(deriveEventCodecSkeleton defaultEventCodecOptions ''OrderEvent)
```

four top-level bindings are emitted, prefixed by the lower-cased type name:

```haskell
orderEventToJSON     :: OrderEvent -> Aeson.Value
orderEventFromJSON   :: Aeson.Value -> Either String OrderEvent
orderEventEventTypes :: [Text]                 -- constructor names, in order
orderEventKindMap    :: [(Text, Text)]         -- (constructor, kind) pairs
```

Each constructor encodes to a JSON object with a `"kind"` discriminator (the constructor
name) plus one entry per payload field; the decoder reads `"kind"`, branches, and reassembles
the payload field by field. The `EventTypes`/`KindMap` lists are handy for wiring a Keiro
runtime's `eventTypes` registry.

Use `deriveEventCodecSkeletonAs "myPrefix" opts ''OrderEvent` if you need an explicit prefix.

## No silent generic fallback (the anti-drift property)

This is the point of the skeleton over a blanket `deriveJSON`. Every payload field is encoded
one of three ways, chosen by **field name**:

- a name in `fieldCodecOverrides` uses the author-supplied `FieldCodec` functions;
- a name in `passthroughFields` uses the field type's own `ToJSON`/`FromJSON`;
- otherwise the field is *unhandled*, and `onMissingCodec` decides.

There is never a quiet generic guess. `onMissingCodec` is either:

- **`FailAtCompileTime`** (the default) — the splice aborts, listing every unhandled field, so
  you must make a decision; or
- **`EmitTodoBindings`** — emits clearly-named `_todo_Event_field` placeholders that compile
  but are `error "TODO: ..."`-bodied, letting you stage the work.

Either way, **adding a field to a payload record forces a compile-time decision** — the stored
JSON cannot silently drift from the event shape.

## Options

```haskell
data EventCodecOptions = EventCodecOptions
  { fieldCodecOverrides :: Map String FieldCodec  -- per-field-name custom encode/decode
  , passthroughFields   :: Set String             -- fields that may use their own aeson instances
  , kindFieldName       :: String                 -- discriminator key; default "kind"
  , onMissingCodec      :: OnMissingCodec          -- FailAtCompileTime (default) | EmitTodoBindings
  }

defaultEventCodecOptions  -- empty overrides/passthrough, kind="kind", FailAtCompileTime
```

Typical use: list the fields whose types already have aeson instances in `passthroughFields`,
supply a `FieldCodec` for anything bespoke in `fieldCodecOverrides`, and keep
`FailAtCompileTime` so new fields can't slip through.

## Why a separate package

`keiki-codec-json` exists so Keiki core stays aeson-free (a load-bearing constraint). The
generated code references aeson but is produced by Template Haskell quotation, so a consumer
module needs only `TemplateHaskell` and the splice — it imports neither aeson nor the codec
helpers directly. Do **not** add an aeson dependency to a module just to hand-write event JSON;
reach for the skeleton instead.

See also the package's own `README` / `Keiki.Codec.JSON.Event` haddock in the Keiki repo for
a full worked example and the negative-case (compile-failure) procedure.
