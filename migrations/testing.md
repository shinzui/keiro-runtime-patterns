# Migration Testing

**Apply the complete composed plan to a fresh PostgreSQL instance and inspect both layers of every nested result.**

Use this guide for service migration tests. It covers pure construction checks, the ephemeral-database harness, its nested `Either` shape, and the fleet wrapper convention.

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

## Related Patterns

- [Service Migration Packages](./service-package.md)
- [Migration Authoring](./authoring.md)
- [Migration Operations](./operations.md)

