# Migration Standards

**Start with the pg-migrate model, then give every service one component, one complete plan, and one migration executable.**

This area is the fleet’s prescriptive guide to database evolution for Keiro services. It covers compile-time plans, immutable SQL authoring, service packaging, deployment, testing, and the completed Codd transition.

## Start here

1. [The pg-migrate Model](./pg-migrate-model.md) — components, manifests, embedding, execution, and the ledger.
2. [Service Migration Packages](./service-package.md) — the standard service component, dependency order, and CLI executable.
3. [Migration Authoring](./authoring.md) — append-only SQL and manifest rules.

## Test and operate

- [Migration Testing](./testing.md) — pure construction checks, ephemeral PostgreSQL, and nested results.
- [Migration Operations](./operations.md) — inspect, apply, verify, and repair.
- [Codd Transition](./codd-transition.md) — why persistent fleets imported history ledger-only.

## Related Patterns

- [Kiroku Event-Store Standards](../kiroku/README.md)
- [Keiki Transducer Standards](../keiki/README.md)
