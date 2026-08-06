---
type: Standard
title: "Kiroku Connection Settings"
description: "Store schema and NOTIFY channel, extraSearchPath seam, timeouts, and synchronous handler discipline"
timestamp: 2026-07-30T01:11:55Z
generated:
  by: human:nadeem
  at: "2026-07-30T01:11:55Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-connection-settings
tags: [kiroku, connection-settings]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T16:52:58Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved kiroku-project checkout (kiroku-store, adapters, otel, metrics) and the keiro consumer's Connection API; changes requested: the extraSearchPath=["keiro"] prescription contradicts keiro's released Connection API.
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T01:11:55Z
    document_timestamp: 2026-07-30T01:11:55Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction against keiro's Connection API and kiroku-store 0.3.1.0: the search-path guidance now appends the application projection schema and excludes the keiro schema.
---

# Kiroku Connection Settings

**Keep the `kiroku` schema authoritative, expose application schemas explicitly, and bound every production statement.**

Use this guide when constructing `ConnectionSettingsM` with `defaultConnectionSettings`. It defines the fleet defaults for schema resolution, pools, timeouts, callbacks, and store startup.

## Keep one authoritative schema setting

Leave `schema = "kiroku"` fleet-wide. The setting controls both table resolution and the `LISTEN` channel: pooled connections use `search_path`, while the notifier listens on `<schema>.events`. A custom schema therefore requires a matching migration and privileges; changing only runtime configuration creates a broken store.

Kiroku installs no DDL in `withStore`. Run the complete migration plan before opening the store.

## Expose application tables through `extraSearchPath`

`extraSearchPath` defaults to `[]`. Keiro services append their application projection schema through `keiroConnectionSettings` (or `withProjectionSchema`) so unqualified application SQL resolves on the store pool. A service whose projections live in `danwa` then uses:

```sql
SET search_path TO "kiroku", "danwa", pg_catalog;
```

Never add the `keiro` framework schema to `extraSearchPath`: Keiro's runtime queries are fully schema-qualified and must not depend on `search_path`. The Kiroku schema remains first, application schemas follow, and `pg_catalog` remains last. Do not rely on `public` appearing implicitly.

## Use bounded fleet defaults

`defaultConnectionSettings` starts with `poolSize = 10`, `idleInTransactionTimeout = 30`, and `statementTimeout = Nothing`. Keep the pool and idle timeout unless load testing establishes another value. Override the production statement timeout to `Just 30`; the library default deliberately inherits PostgreSQL’s usually-unbounded session setting.

```haskell
settings = withProjectionSchema "danwa" base
  where
    base =
      (defaultConnectionSettings databaseUrl)
        { statementTimeout = Just 30
        }
```

## Keep synchronous hooks fast

Both `eventHandler` and `observationHandler` run synchronously on the emitting store, notifier, publisher, worker, or pool thread. Use them only for bounded in-memory updates or enqueue work into a bounded queue drained elsewhere. Network I/O or a blocking exporter in either callback can stall store operation.

Build all handlers and `storeSettings` before calling `withStore`; the resulting handle captures them for its lifetime. When several effectful actions must share one open store, `runKirokuStoreWith` (kiroku-store 0.3.1.0) runs them against a single acquired handle instead of paying a pool, `LISTEN` connection, and publisher per action.

## Related Patterns

- [Operational Invariants](./operational-invariants.md)
- [Observability](./observability.md)
- [Transactions and Projections](./transactions-and-projections.md)
