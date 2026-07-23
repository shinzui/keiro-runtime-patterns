---
type: Standard
title: "Test Layout"
description: "The per-package test-suite standard: four core suites, vertical Spec modules, migrations test-support"
timestamp: 2026-07-22T11:42:26-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-test-layout
tags: [architecture, test-layout]
status: current
---

# Test Layout

**Tests mirror vertical source modules, and every package owns the suites that prove its responsibility.**

The baseline comes from danwa's six-package structure; services using keiro-dsl's extended node vocabulary add the focused suites demonstrated by keiro-runtime-jitsurei. Database tests always provision isolated PostgreSQL through the migrations package's public `test-support` sublibrary and never use a developer database.

## Core Owns Four Baseline Suites

`<service>-core-test`, under `test/`, is the ordinary core smoke and unit suite.

`<service>-core-domain`, under `test-domain/`, is a deliberately small executable driver rather than a Tasty tree. It concatenates every aggregate's generated `harnessAssertions`, prints each result, and exits with failure if any assertion is false. Its only dependencies are `base` and `<service>-core`, so domain validation never waits for PostgreSQL.

`<service>-core-diagrams`, under `test-diagrams/`, uses Tasty to assert that the generated Mermaid lifecycle documentation has no stale diagrams and that every rendered diagram passes keiki's structural validation. This suite keeps documentation derived from transducers in sync with executable behavior.

`<service>-core-postgres`, under `test-postgres/`, provisions an ephemeral migrated database through `<service>-migrations:test-support`. It round-trips a real event through kiroku and exercises read-model writes and queries against PostgreSQL.

## Migrations, Server, And Workers Own Their Boundaries

`<service>-migrations-test` verifies migration filename and slug rules, generated templates, the composed schemas and ledger, and an idempotent second migration run. The migrations package publishes a visible `test-support` sublibrary with a service-specific wrapper such as `withDanwaMigratedDatabase`; every call creates an isolated migrated database and tears it down afterward.

`<service>-server-test` drives real handlers against an ephemeral migrated database and observes their external effect. Danwa's suite calls the StartConversation handler and then reads kiroku to prove that one `ConversationStarted` event was appended.

`<service>-workers-test` has `test/Main.hs` as a Tasty aggregator. Its other modules mirror the source verticals and export `tests :: TestTree`:

```text
src/<Service>/Conversation/Worker.hs
test/<Service>/Conversation/WorkerSpec.hs

src/<Service>/Integration/AddressedMessageWorker.hs
test/<Service>/Integration/AddressedMessageWorkerSpec.hs

src/<Service>/Workers/Registry.hs
test/<Service>/Workers/RegistrySpec.hs
```

Every worker module gets a corresponding `*Spec`; danwa's missing `Embellishment/WorkerSpec.hs` is a known reference gap, not permission to omit coverage. Use Tasty and tasty-hunit for the package suites unless a specialized driver, such as the generated domain harness, has a narrower dependency surface.

## Extended Suites For Richer Services

Keiro-runtime-jitsurei's hospital-capacity package demonstrates six focused suite roles. In a six-package service, attach each role to the package that owns the tested surface:

- `test` is the baseline unit suite.
- `dsl-test` checks scaffolded modules, harnesses, and specification conformance; attach it to `<service>-core`.
- `contract-test` checks integration-event contracts; attach it to `<service>-workers`.
- `migration-test` checks the pg-migrate plan; attach it to `<service>-migrations`.
- `kafka-integration` runs real-broker integration tests; attach it to `<service>-workers` and keep it operationally distinct from unit tests.
- `symbolic-test` is an optional additive keiki/SBV suite for transducer proofs; attach it to `<service>-core` and document that it requires `z3` on `PATH`.

Use the service name as the cabal prefix, for example `<service>-dsl-test` and `<service>-contract-test`. Specialized suites augment the four core baselines and the package suites; they do not justify collapsing the six package boundaries.

## Database Isolation Rule

No test opens a developer or shared database. Core, server, and worker integration suites receive their connection string only from `<service>-migrations:test-support`, which installs the same complete migration plan used by the service. This makes schema ownership executable and ensures tests fail when the runtime and migration package disagree.

## Related Patterns

- [Service packages](service-packages.md)
- [Vertical-slice modules](vertical-slice-modules.md)
- [Migration testing](../migrations/testing.md)
- [Keiki build-time validation](../keiki/build-time-validation.md)
- [Kiroku transactions and projections](../kiroku/transactions-and-projections.md)
