---
type: Standard
title: "Kiroku Connection Settings"
description: "Store schema and NOTIFY channel, extraSearchPath seam, timeouts, and synchronous handler discipline"
timestamp: 2026-07-22T09:52:58-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-connection-settings
tags: [kiroku, connection-settings]
status: current
---

# Kiroku Connection Settings

**Keep the `kiroku` schema authoritative, expose application schemas explicitly, and bound every production statement.**

Use this guide when constructing `ConnectionSettingsM` with `defaultConnectionSettings`. It defines the fleet defaults for schema resolution, pools, timeouts, callbacks, and store startup.

## Keep one authoritative schema setting

Leave `schema = "kiroku"` fleet-wide. The setting controls both table resolution and the `LISTEN` channel: pooled connections use `search_path`, while the notifier listens on `<schema>.events`. A custom schema therefore requires a matching migration and privileges; changing only runtime configuration creates a broken store.

Kiroku installs no DDL in `withStore`. Run the complete migration plan before opening the store.

## Expose application tables through `extraSearchPath`

`extraSearchPath` defaults to `[]`. Keiro services that update framework projections through the Kiroku pool set it to `["keiro"]`. Each connection then uses:

```sql
SET search_path TO "kiroku", "keiro", pg_catalog;
```

The Kiroku schema remains first, application or framework schemas follow, and `pg_catalog` remains last. Do not rely on `public` appearing implicitly.

## Use bounded fleet defaults

`defaultConnectionSettings` starts with `poolSize = 10`, `idleInTransactionTimeout = 30`, and `statementTimeout = Nothing`. Keep the pool and idle timeout unless load testing establishes another value. Override the production statement timeout to `Just 30`; the library default deliberately inherits PostgreSQL’s usually-unbounded session setting.

```haskell
settings =
  (defaultConnectionSettings databaseUrl)
    { extraSearchPath = ["keiro"]
    , statementTimeout = Just 30
    }
```

## Keep synchronous hooks fast

Both `eventHandler` and `observationHandler` run synchronously on the emitting store, notifier, publisher, worker, or pool thread. Use them only for bounded in-memory updates or enqueue work into a bounded queue drained elsewhere. Network I/O or a blocking exporter in either callback can stall store operation.

Build all handlers and `storeSettings` before calling `withStore`; the resulting handle captures them for its lifetime.

## Related Patterns

- [Operational Invariants](./operational-invariants.md)
- [Observability](./observability.md)
- [Transactions and Projections](./transactions-and-projections.md)
