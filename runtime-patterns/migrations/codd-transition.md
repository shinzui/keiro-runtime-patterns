---
type: Guide
title: "Codd to pg-migrate Transition"
description: "Why the fleet moved from codd to pg-migrate and how persistent databases were imported ledger-only"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-codd-transition
tags: [migrations, codd-transition]
status: current
---

# Codd to pg-migrate Transition

**Import persistent history into the new ledger without replaying DDL, and claim only the evidence strength the old database can prove.**

Use this explainer to understand the fleet’s one-time transition from Codd. It is context for current migration ownership, not a production migration runbook.

## Why the model changed

Codd keyed applied migrations by filename alone. pg-migrate uses component-local durable identities, exact payload checksums, explicit dependencies, and one application-owned plan. Kiroku and Keiro moved first; their native SQL files gained ordered `0001`-style names, and Keiro relocated framework tables from schema `kiroku` to its dedicated `keiro` schema.

The current runtime has one pg-migrate ledger for the Kiroku, Keiro, pgmq, and service components. Codd tooling remains only behind Keiro’s off-by-default `legacy-codd-tools` flag.

## Import history, never reapply it

A database with real application data cannot be dropped and rebuilt merely to change migration runners. The cutover reads Codd’s ledger and writes equivalent pg-migrate migration and audit rows. It does not execute the target migration actions or replay DDL.

The operation is one-time, forward-only, and performed while legacy writers are quiesced. After import, strict pg-migrate verification must explain the complete target history before new migrations run.

`up` now enforces the ordering itself: it refuses to run against a database that still carries a codd ledger while native pg-migrate history is absent or empty, because doing so would initialize a fresh ledger and re-plan every migration over a populated database. Import first, or pass `--allow-fresh-ledger-over-codd` when a fresh native ledger over the retired codd ledger is genuinely intended.

## Keep the cutover lockfile frozen

Where a component ships both a `migrations.lock` and a `migrations.native.lock`, they are different artifacts. The plain `migrations.lock` is **frozen codd-cutover evidence**: strict history import depends on its exact legacy filename set. Never add a native entry to it. New migrations extend `migrations.native.lock` only — see [Migration Authoring](./authoring.md).

## State evidence honestly

Use `SamePayload` only when manifest-backed checksums and reviewed source bytes prove the target migration payload is the same payload represented by the Codd history. Use `EquivalentState` when the old checksum-blind workflow allowed a legitimate rewrite and a read-only state validator proves the target database state instead. Never upgrade validator-backed equivalence into a checksum claim.

`Kiroku.Store.Migrations.History.Codd` is the worked example: it maps the seven historical Codd filenames to native `0001` through `0007` identities with `SamePayload` evidence. Later native migrations do not need legacy mappings.

## Use the cohort procedure for production

For an old-cohort production database, use the `cohort-migrate` agent skill. That procedure inventories the cohort, restores a clone, composes the exact remediation, proves preservation and verification on the clone, and only then produces the production action. Do not improvise from this explainer against a live database.

## Related Patterns

- [Migration Operations](./operations.md)
- [The pg-migrate Model](./pg-migrate-model.md)
- [Migration Testing](./testing.md)
