---
type: Standard
title: "Runtime assembly"
description: "Store acquisition, validated event streams, resource effects, options, and startup order"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-runtime-assembly
tags: [keiro, runtime-assembly]
status: current
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

Warnings—including head-recoverability, inversion ambiguity, unguarded input reads, and state-changing silent edges—mean the transducer must be corrected. `mkEventStreamOrThrow` is reserved for generated definitions or fixtures with a colocated validation proof. `mkEventStreamUnchecked` skips the durable boundary entirely and is permitted only in tests or emergency forensics, never production wiring.

Validation now covers the **event codec** as well as the transducer. Construction is refused when the codec's schema version, event tags, or upcaster chain fail `mkCodec`, so a missing rung or a pair of conflicting sources is caught at startup rather than at the first hydration of an old stream. Hand-written streams get the same fail-fast treatment as generated ones; the generator's own checks are defense in depth, not the only gate.

See [build-time validation](../keiki/build-time-validation.md) for the transducer checks and [evolution gates and rollout ordering](evolution-and-rollout.md) for how this boundary relates to the specification-level gates.

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

The rule is one sentence: migrate as a deployment job, prove the migration handshake in every replica, acquire the store, validate event streams, register read models, then start only the workers the service uses.

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
- [Command cycle and errors](command-cycle-and-errors.md)
- [Keiro gotchas](gotchas.md)
- [Read models and projections](read-models-and-projections.md)
- [Migration Operations](../migrations/operations.md)
