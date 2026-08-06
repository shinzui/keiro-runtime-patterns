---
type: Standard
title: "Runtime assembly"
description: "Store acquisition, validated event streams, structural mapping evidence, resource effects, options, and startup order"
timestamp: 2026-08-06T22:43:02Z
generated:
  by: human:nadeem
  at: "2026-08-06T22:43:02Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-runtime-assembly
tags: [keiro, runtime-assembly]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T02:53:40Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Runtime assembly

**Acquire the store once with `withKirokuStore`, validate every event stream at startup, and thread options through lenses.**

This standard defines the process-level wiring shared by command handlers, projections, and workers; the keiro repo's `jitsurei/app/Main.hs` is the executable reference.

## Acquire one store resource

The rule is one sentence: bracket the service with `withKirokuStore`, then run store effects through the resource interpreter it provides.

```haskell
type ServiceEffects =
  '[ StoreEffect.Store
   , Error StoreError
   , StoreResource.KirokuStoreResource
   , IOE
   ]

withServiceStore connString appSchema action =
  runEff $
    StoreResource.withKirokuStore
      (keiroConnectionSettings connString appSchema) $
      withEffToIO SeqUnlift \unlift ->
        action
          (unlift . runErrorNoCallStack . StoreEffect.runStoreResource)
```

Use `runCommand` when only the event append must commit. `runCommandWithSql`, `runCommandWithSqlEvents`, and `runCommandWithProjections` add work to the append transaction and therefore require `KirokuStoreResource`; plain `runCommand` does not. Keep transactional callbacks short because they retain kiroku's `$all` row lock until commit.

## Validate definitions once

A **validated event stream** is an `EventStream` admitted by `mkEventStream` after every enabled keiki and keiro replay-safety check passes. Construct these values at startup and give only the `ValidatedEventStream` results to runtime components.

```haskell
validatedOrderStream <-
  case mkEventStream "order" orderStreamDefinition of
    Right stream -> pure stream
    Left warnings -> failStartup warnings
```

Warnings—including head-recoverability, inversion ambiguity, unguarded input reads, state-changing silent edges, unsupported field-projection results, ordered projections over unsupported types, and projections outside guards—mean the transducer must be corrected. `mkEventStreamOrThrow` is reserved for generated definitions or fixtures with a colocated validation proof. `mkEventStreamUnchecked` skips the durable boundary entirely and is permitted only in tests or emergency forensics, never production wiring.

Validation now covers the **event codec** as well as the transducer. Construction is refused when the codec's schema version, event tags, or upcaster chain fail `mkCodec`, so a missing rung or a pair of conflicting sources is caught at startup rather than at the first hydration of an old stream. Hand-written streams get the same fail-fast treatment as generated ones; the generator's own checks are defense in depth, not the only gate.

See [build-time validation](../keiki/build-time-validation.md) for the transducer checks and [evolution gates and rollout ordering](evolution-and-rollout.md) for how this boundary relates to the specification-level gates.

## Compile And Prove Structural Bindings Before Startup

`mkEventStream` validates the assembled codec contract, not the semantic honesty of a consumer-owned `StructuralBinding`. For each `mapped structural` type, compilation and the generated harness must first exercise both binding round trips over deterministic fixtures, the declared JSON policies, projection-witness agreement, and forward-versus-replay equality.

The generated event codec is the sole private-event wire authority. A consumer `ToJSON` or `FromJSON` instance may delegate one way through `encodeViaBinding` or `decodeViaBinding`, but Keiro never delegates structural event encoding back to that instance. Mapped register snapshots remain a separate consumer-JSON cache boundary and are invalidated by the mapping/fold fingerprint when their executable shape changes.

Treat this as pre-startup evidence, not another runtime interpreter. See [brownfield Keiro adoption](brownfield-adoption.md) for the binding and historical-codec gates.

## Extend defaults through lenses

The rule is one sentence: begin with the runtime's `default*` options and change named fields through lenses.

```haskell
-- CORRECT: inherits new defaults when the library adds fields.
commandOptions metrics =
  defaultRunCommandOptions & #metrics .~ metrics

-- WRONG: positional or exhaustive reconstruction couples startup to record shape.
commandOptions metrics =
  RunCommandOptions 3 256 [] (pure ()) 5000 metrics True Nothing Nothing
```

Apply the same pattern to subscription, projection, and workflow options.

## Startup order

The rule is one sentence: migrate as a deployment job, prove the migration handshake in every replica, construct telemetry instruments, acquire the store, validate event streams, register read models, then start only the workers the service uses.

Telemetry instruments come before store acquisition, not after it, because `ConnectionSettings` closes over them. `newKirokuMetrics`, the `Tracer`, and `newKeiroMetrics` all feed `eventHandler` or `observationHandler` callbacks that can only be installed at construction time. A service that builds `KeiroMetrics` later, alongside the worker options it also feeds, silently loses every instrument sourced from those callbacks. See [telemetry](telemetry.md) and [Kiroku observability](../kiroku/observability.md).

Applying migrations from a deployment job keeps schema ownership deterministic, but it does not stop a replica from starting before that job reaches its database. Close the gap by refusing to serve until the handshake passes:

```haskell
guardMigrations provider plan = do
  result <- missingMigrations defaultRunOptions provider plan
  case result of
    Right handshake | handshakePassed handshake -> pure ()
    Right handshake -> fail ("refusing startup: " <> show handshake)
    Left err -> fail ("migration handshake failed: " <> show err)
```

`missingMigrations` is a read-only status query, so every replica may call it at boot. `StartupHandshake` reports `pendingMigrations` and `ledgerIssues`; `handshakePassed` requires both to be empty. Open Kiroku with schema initialization disabled afterwards.

Registration and worker startup should fail the process rather than leave a partially assembled runtime alive.

## Related Patterns

- [The two-schema arrangement](two-schema-arrangement.md)
- [Telemetry](telemetry.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [Keiro gotchas](gotchas.md)
- [Read models and projections](read-models-and-projections.md)
- [Migration Operations](../migrations/operations.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
