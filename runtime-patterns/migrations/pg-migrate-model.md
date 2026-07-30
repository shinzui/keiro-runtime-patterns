---
type: Guide
title: "The pg-migrate Model"
description: "The pg-migrate model: components, manifests, exact-byte embedding, the ledger, the RecompilePlugin, and its layered integrity gates"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-pg-migrate-model
tags: [migrations, pg-migrate-model]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-23T16:55:16-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro-migrations, kiroku-store-migrations, and pg-migrate source and CLIs; verified exported symbols, signatures, version claims, and links.
---

# The pg-migrate Model

**Libraries export stable migration components; applications compose and run one compile-time plan.**

Use this guide to understand pg-migrate 1.1 before authoring service migrations. It covers component ownership, manifest embedding, plan validation, execution, and the durable ledger.

## Model ownership as components

A `MigrationComponent` has a stable name, a `Set` of component-name dependencies, and a non-empty ordered migration list. Migration identity is the component name plus the local migration name, such as `accounts/0001-create-accounts`.

For embedded SQL, the local name is the manifest filename without `.sql`. That basename is durable history: renaming the file changes identity. Never rename, reorder, remove, or modify an applied entry.

Use `migrationPlan` when the application lists components in authoritative order; it validates that every dependency is present and precedes its consumer. Use `resolveMigrationPlan` only for a registration layer that genuinely receives an unordered collection; it performs a stable topological sort.

## Embed exact bytes from a manifest

Each component owns a plain `manifest` file containing one SQL filename per line in execution order. `embedMigrationManifest` validates membership at compile time and embeds the exact bytes. `migrationComponentFromEmbeddedSql` removes `.sql`, validates each migration, determines transaction mode, and hashes the exact payload with SHA-256.

Every embedding module on GHC 9.12 must carry the plugin pragma so adding an unlisted sibling file forces the membership audit to run:

```haskell
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fplugin=Database.PostgreSQL.Migrate.Embed.RecompilePlugin #-}
```

Production binaries execute embedded bytes. They do not discover migration files at runtime.

## Layer the integrity gates

The plugin has an explicit limit: it reruns the membership check whenever Cabal invokes GHC, and it can do nothing when Cabal decides the package is already up to date and never invokes the compiler. Do not treat it as the only defense.

Three independent layers cover the gap, each at a different time:

| When | Gate | What it proves |
| --- | --- | --- |
| Compile | `embedMigrationManifest` plus `RecompilePlugin` | Order, directory membership, and exact SQL payloads — whenever GHC actually runs. |
| Review | Default test suite reading the lockfile and directory | The lockfile, manifest, membership, and every SHA-256 payload agree, independent of build staleness. |
| Deploy | The `pgmigrate` ledger | Applied history is keyed by checksum and fails closed on divergence. |

No layer replaces another. See [Migration Testing](./testing.md) for the review-time suite and [Migration Operations](./operations.md) for the deploy-time gates.

## Run the complete plan under one lock

`up` holds a session advisory lock for the complete plan. Transactional SQL and its applied ledger row commit atomically; rerunning an already applied plan produces `AlreadyApplied` results. Nontransactional work uses a durable state machine and has a stricter recovery procedure.

The default ledger lives in schema `pgmigrate`. Migration rows are keyed by `(component, migration)`, carry a 32-byte SHA-256 checksum, kind, transaction mode, position, and status. Repair and history-import evidence is append-only. A binary that supports an older ledger schema refuses a database with a newer one.

pg-migrate is forward-only and supports PostgreSQL 17 and 18. A service owns one connection source—normally `DATABASE_URL`—and one complete plan. It does not maintain separate per-library runners.

## Related Patterns

- [Migration Authoring](./authoring.md)
- [Service Migration Packages](./service-package.md)
- [Migration Operations](./operations.md)
