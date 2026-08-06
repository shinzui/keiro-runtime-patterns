---
type: Guide
title: "Migration Testing"
description: "Integrity gates in the default suite, ephemeral-database tests with withMigratedDatabase, the nested-Either gotcha, and per-service wrappers"
timestamp: 2026-07-30T01:11:55Z
generated:
  by: human:nadeem
  at: "2026-07-30T01:11:55Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-testing
tags: [migrations, testing]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-23T23:55:16Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro-migrations, kiroku-store-migrations, and pg-migrate source and CLIs; changes requested: the nested Either example names hasql-pool's UsageError where hasql 1.10 returns SessionError, and the per-service helper convention does not exist.
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
      Model re-review of the correction against hasql 1.10 and keiro-test-support: the nested Either names SessionError and the suite fixture convention matches the reference service.
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

When the callback uses `Connection.use`, the result is nested: `Either MigratedDatabaseError (Either SessionError value)`. An outer `Right` means the test callback completed; it does not mean the Hasql session succeeded.

```haskell
-- WRONG: silently accepts a Hasql Left inside the callback result.
Right _ -> pure ()

-- CORRECT: require success from the harness and the Hasql session.
Right (Right value) -> assertExpected value
Right (Left sessionError) -> assertFailure (show sessionError)
Left migrationError -> assertFailure (show migrationError)
```

## Wrap the complete service plan

Each service wraps its complete plan once at the suite boundary. The fleet convention is keiro-test-support's template-database fixture: `withMigratedSuiteWith` applies Kiroku's, Keiro's, and any extra components (for example pgmq's) to one template database that every example clones; jitsurei's `withJitsureiSuite` is the reference. Where a per-test database fits better, wrap the same complete plan in a `withMigratedDatabase` helper. Either way, fail loudly on `Left`; tests still inspect any application-level or Hasql `Either` returned by their callback.

Assert fresh apply, idempotent rerun with `AlreadyApplied`, strict verification, and behavior that depends on every component. For data changes, also apply the old released plan, insert representative data, upgrade with the new plan, and assert the transformed state.

Cover the negative paths too. A gate that has never been observed failing is not known to work: assert that a tampered payload, an unlisted sibling file, and a drifted live object each produce their named failure.

## Related Patterns

- [Service Migration Packages](./service-package.md)
- [Migration Authoring](./authoring.md)
- [Migration Operations](./operations.md)
