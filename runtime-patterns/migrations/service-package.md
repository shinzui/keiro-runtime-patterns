---
type: Standard
title: "Service Migration Packages"
description: "The <service>-migrations package pattern composing kiroku, keiro, pgmq, and service components into one plan"
timestamp: 2026-07-22T09:54:51-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-service-package
tags: [migrations, service-package]
status: current
---

# Service Migration Packages

**Give each service an embedded migration component and one migration executable that owns the complete dependency-ordered plan.**

Use this guide when adding migrations to a Keiro service. It defines package ownership, component dependencies, plan order, schema boundaries, and CLI mounting.

## Export one service component

Create a `<service>-migrations` library or dedicated library component. Export a stable service component whose name is the service slug and whose dependency is `keiro`:

```haskell
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fplugin=Database.PostgreSQL.Migrate.Embed.RecompilePlugin #-}

serviceMigrations :: Either DefinitionError MigrationComponent
serviceMigrations =
  migrationComponentFromEmbeddedSql
    "incident-command"
    (Set.singleton "keiro")
    $(embedMigrationManifest "migrations/application/manifest")
```

The service component owns only service DDL. Kiroku owns schema `kiroku`, Keiro owns schema `keiro`, pgmq owns its queue schema, and the service owns a dedicated application schema. Do not copy dependency SQL into the service package.

## Compose one application plan

Resolve all component definition results and compose them once, in this order:

```haskell
servicePlan :: Either DefinitionError (Either PlanError MigrationPlan)
servicePlan = do
  kiroku <- kirokuMigrations
  keiro <- keiroMigrations
  pgmq <- pgmqMigrations       -- include only when the service uses pgmq
  service <- serviceMigrations
  pure (migrationPlan (kiroku :| [keiro, pgmq, service]))
```

For a service without pgmq, omit that component but retain `kiroku :| [keiro, service]`. Consume `kirokuMigrations`, the component export, rather than treating `kirokuMigrationPlan` as a composable unit. `kirokuMigrationPlan` is only the Kiroku package’s single-component convenience plan.

The pg-migrate basic example demonstrates the same rule with independent `accounts` and dependent `billing` components. The runtime jitsurei applies it in real service migration libraries, including the optional pgmq component.

## Mount one service-owned executable

Ship `<service>-migrate`. Parse `migrationCommandParser plan`, build the environment from application configuration, and dispatch with `runMigrationCommand`:

```haskell
let environment =
      cliEnvironment
        (Settings.connectionString databaseUrl)
        plan
        defaultRunOptions
outcome <- runMigrationCommand environment parsedCommand
```

`pg-migrate-cli` is a library, not a generic binary. The application owns `DATABASE_URL`, secrets, precedence, rendering, logging, and process exit codes. The executable must carry the exact embedded plan shipped with the service artifact.

## Related Patterns

- [The pg-migrate Model](./pg-migrate-model.md)
- [Migration Authoring](./authoring.md)
- [Migration Operations](./operations.md)
