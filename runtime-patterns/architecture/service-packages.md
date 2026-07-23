---
type: Standard
title: "Six Packages Per Deployed Service"
description: "The six-package split standard for deployed keiro services and its dependency rules"
timestamp: 2026-07-22T11:39:26-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages
tags: [architecture, service-packages]
status: current
---

# Six Packages Per Deployed Service

**A deployed keiro service is exactly six cabal packages with explicit dependency budgets.**

The package split keeps domain decisions, HTTP types, HTTP execution, background processing, schema installation, and client consumption independently buildable. Use the service's lowercase name in place of `<service>` and keep all six packages in one repository.

## The Six Packages

### `<service>-core`

This package owns the domain. It contains the custom `Prelude`, `App.Config`, each concept's generated ring, `Holes`, and `ReadModel`, the shared `Postgres.Pool` and `Postgres.Runner`, public `Integration.*` contracts, and `Diagrams` support. It may depend on keiki, kiroku, keiro, hasql, and domain-level libraries, but it depends on no sibling `<service>-*` package. Every other service package may depend on core.

Danwa realizes this boundary under `danwa-core/src/Danwa/` and exposes the lifecycle-diagram program as the `danwa-diagrams` executable.

### `<service>-api`

This package owns servant route records and wire data-transfer types. It depends on `<service>-core` and servant's type-level API library, but not `servant-server` or warp. Keep handler execution and resource acquisition out of it.

Danwa realizes this boundary in `danwa-api/src/Danwa/Api.hs` and the per-concept `Danwa.<Concept>.Api` modules.

### `<service>-server`

This package owns the HTTP application: `Server.App`, `Server.Boot`, `Server.Config`, `Server.Seam`, per-concept `Handler` modules, and the `<service>-server` executable. It depends on `<service>-core`, `<service>-api`, servant-server, warp, and the runtime packages needed to execute commands and queries.

### `<service>-workers`

This package owns Shibuya-supervised background processing: `Workers.Config`, `Workers.Registry`, `Workers.Subscription`, per-concept workers, integration workers, and the `<service>-worker` executable. It depends on `<service>-core`, keiro, Shibuya, and the chosen queue adapters. It never depends on `<service>-api` or `<service>-server`; a worker must not acquire an HTTP-layer dependency merely to reuse application behavior.

### `<service>-migrations`

This package owns schema migrations, plan composition, the `new <description>` migration scaffold, and the `<service>-migrate` executable. New services use pg-migrate; danwa's codd package remains useful structural evidence but is not the current migration-tool choice. Migrations depend on the migration toolchain and no other `<service>-*` library, so operators can build and run them without building the domain or server.

Publish a visible `test-support` sublibrary that provisions an ephemeral, fully migrated PostgreSQL database. The test suites in core, server, and workers depend on `<service>-migrations:test-support`; production libraries do not. Danwa's realization is `danwa-migrations/test-support/Danwa/Migrations/TestSupport.hs` with `visibility: public`.

### `<service>-client`

This package owns the typed Haskell client derived from `<service>-api`. It depends on the API package and servant-client, never on the server package. Other Haskell services can therefore call the API without linking server implementation or runtime resources.

## Dependency Direction

The allowed sibling dependencies form this graph:

```text
<service>-core        ← every application package may depend on it;
   │                    it depends on no sibling package
   ├── <service>-api            → core
   │        ├── <service>-server → core, api
   │        └── <service>-client → api
   ├── <service>-workers        → core
   └── <service>-migrations     → no sibling package
                                  public test-support ← test suites only
```

Dependency arrows must not point back toward server or workers. In particular, migrations do not import core, workers do not import API or server, and client does not import server.

## Production Ruling

The six-package split is both the floor and the ceiling for a deployed fleet service. Do not create a seventh package merely to collect PostgreSQL, Kafka, or other technical code; danwa removed its former `danwa-postgres` package and kept the shared database wiring in core.

Keiro-runtime-jitsurei's one-cabal-package-per-service shape is acceptable only for teaching and example repositories, where keeping a library, CLIs, and several test suites together makes a walkthrough easier to follow. A repository using that exception must say so in its README. It is not a production deployment template.

## Related Patterns

- [Vertical-slice modules](vertical-slice-modules.md)
- [Cross-cutting modules](cross-cutting-modules.md)
- [Test layout](test-layout.md)
- [Migration service package](../migrations/service-package.md)
