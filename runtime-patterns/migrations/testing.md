---
type: Guide
title: "Migration Testing"
description: "Integrity gates in the default suite, ephemeral-database tests with withMigratedDatabase, the nested-Either gotcha, and per-service wrappers"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-testing
tags: [migrations, testing]
status: current
---

# Migration Testing

**Apply the complete composed plan to a fresh PostgreSQL instance and inspect both layers of every nested result.**

Use this guide for service migration tests. It covers pure construction checks, the ephemeral-database harness, its nested `Either` shape, and the fleet wrapper convention.

## Keep the integrity gates in the default build

The rule is one sentence: a gate behind an opt-in cabal flag is a gate nobody runs.

Every integrity check belongs in the normal test components so a regression cannot depend on someone remembering to enable a flag:

- a **body lint** rejecting unqualified DDL targets and any migration that manipulates `search_path`;
- a **lockfile gate** reading the lockfile and the migrations directory at test runtime and requiring the lockfile, manifest, directory membership, and every SHA-256 payload to agree;
- an **expected-schema comparison** against a fresh database.

Regenerate an expected-schema snapshot only after an intentional schema change, explicitly, and review the resulting diff:

```bash
KEIRO_REGENERATE_EXPECTED_SCHEMA=1 \
  cabal test keiro-migrations-test \
  --test-options='--match "checked-in snapshot"'
```

The default suite never regenerates the file. It fails on drift, which is the point.

## Check construction before PostgreSQL

Compile every `embedMigrationManifest` module, run `check --manifest`, and evaluate the final service plan in a pure test. This catches manifest membership, SQL-definition, component-order, and dependency errors without acquiring a connection.

These checks do not prove PostgreSQL accepts or implements the DDL. Keep an integration test for the complete plan.

## Use `withMigratedDatabase`

`withMigratedDatabase` brackets an ephemeral PostgreSQL server, applies the full `MigrationPlan`, releases the runner connection, and gives the callback a fresh Hasql connection:

```haskell
withMigratedDatabase
  :: MigrationPlan
  -> (Connection -> IO value)
  -> IO (Either MigratedDatabaseError value)
```

Use `withMigratedDatabaseOptions` to customize runner options and `withMigratedDatabaseConfig` when the ephemeral server itself needs configuration. Keep `pg-migrate-test-support` out of the production dependency closure.

## Match both `Either` layers

When the callback uses `Connection.use`, the result is nested: `Either MigratedDatabaseError (Either UsageError value)`. An outer `Right` means the test callback completed; it does not mean the Hasql session succeeded.

```haskell
-- WRONG: silently accepts a Hasql Left inside the callback result.
Right _ -> pure ()

-- CORRECT: require success from the harness and the Hasql session.
Right (Right value) -> assertExpected value
Right (Left usageError) -> assertFailure (show usageError)
Left migrationError -> assertFailure (show migrationError)
```

## Wrap the complete service plan

Each service exports a `with<Service>MigratedDatabase` test helper. The wrapper constructs the service’s complete Kiroku, Keiro, optional pgmq, and application plan; calls `withMigratedDatabase`; unwraps the outer result; and fails loudly on `Left`. Tests still inspect any application-level or Hasql `Either` returned by their callback.

Assert fresh apply, idempotent rerun with `AlreadyApplied`, strict verification, and behavior that depends on every component. For data changes, also apply the old released plan, insert representative data, upgrade with the new plan, and assert the transformed state.

Cover the negative paths too. A gate that has never been observed failing is not known to work: assert that a tampered payload, an unlisted sibling file, and a drifted live object each produce their named failure.

## Related Patterns

- [Service Migration Packages](./service-package.md)
- [Migration Authoring](./authoring.md)
- [Migration Operations](./operations.md)
