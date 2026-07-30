---
type: Overview
title: "Migration Standards"
description: "Index of pg-migrate migration standards for keiro services; start here"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-overview
tags: [migrations, overview]
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

# Migration Standards

**Start with the pg-migrate model, then give every service one component, one complete plan, and one migration executable.**

This area is the fleet’s prescriptive guide to database evolution for Keiro services. It covers compile-time plans, immutable SQL authoring, service packaging, deployment, testing, and the completed Codd transition.

Integrity is layered on purpose: compile-time embedding, a review-time lockfile and body lint, a boot-time startup handshake, and two deploy-time gates — `verify` for the ledger and `verify-schema` for live objects. No layer substitutes for another.

## Start here

1. [The pg-migrate Model](./pg-migrate-model.md) — components, manifests, embedding, execution, and the ledger.
2. [Service Migration Packages](./service-package.md) — the standard service component, dependency order, and CLI executable.
3. [Migration Authoring](./authoring.md) — append-only SQL and manifest rules.

## Test and operate

- [Migration Testing](./testing.md) — default-build integrity gates, pure construction checks, ephemeral PostgreSQL, and nested results.
- [Migration Operations](./operations.md) — inspect, apply, verify ledger and live schema, and repair.
- [Codd Transition](./codd-transition.md) — why persistent fleets imported history ledger-only.

## Related Patterns

- [Kiroku Event-Store Standards](../kiroku/overview.md)
- [Keiki Transducer Standards](../keiki/overview.md)
