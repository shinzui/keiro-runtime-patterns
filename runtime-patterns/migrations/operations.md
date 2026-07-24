---
type: Runbook
title: "Migration Operations"
description: "Operating verify, verify-schema, status, and repair; the codd preflight; Running after a crash needs audited repair"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-operations
tags: [migrations, operations]
status: current
---

# Migration Operations

**Review the complete embedded plan, apply it in one deployment job, and repair nontransactional ambiguity only from audited evidence.**

Use this runbook to inspect, apply, verify, or repair a service’s pg-migrate plan. It distinguishes safe read-only commands from state-changing operations and defines the crash-recovery boundary.

## Use the service executable

Every command supports text and JSON output; use JSON as the stable automation contract.

| Command | Database | Purpose |
| --- | --- | --- |
| `plan` | no | Show component order and dependencies. |
| `list` | no | Show declared migrations and checksums. |
| `check` | no | Validate a manifest’s syntax, membership, and bytes. |
| `status` | yes | Summarize applied, pending, unknown, and inconsistent ledger state. |
| `verify` | yes | Compare the complete declared plan with the ledger. |
| `up` | yes | Apply the complete validated pending suffix. |
| `repair` | yes | Perform one confirmed, audited nontransactional repair. |
| `new` | no | Create a local SQL file and append its manifest entry. |
| `verify-schema` | yes | Compare live schema objects with the embedded expected snapshot. |

Run `plan`, `status`, and strict `verify` against the intended database and role before deployment. Pending migrations make strict verification fail before `up`; this is expected. After `up`, strict verification must succeed.

## Verify the ledger and the live schema separately

The two gates answer different questions and neither substitutes for the other. Run both around every deployment, restore, and cutover.

`verify` compares the embedded plan with pg-migrate’s durable ledger. It detects checksum, identity, position, kind, transaction-mode, status, gap, and unknown-row problems. It does **not** look at live database objects, so a clean ledger can still sit over a hand-altered schema.

`verify-schema` closes that hole for the framework schema. It compares the live tables, columns, constraints, and indexes in the `keiro` schema against a checked-in, sorted expected snapshot, reporting each missing, unexpected, or changed object and exiting non-zero on any drift.

Know its boundaries. The snapshot targets PostgreSQL 18. Roles, grants, database settings, and standalone sequence properties are out of scope; sequence-backed column defaults remain covered as column definitions. It is a Keiro-maintained representation, not a general schema-diff engine. It currently emits text only, while the pg-migrate commands also accept `--json` as the stable automation contract.

Record the artifact identity, target, role, timestamps, and command output. Do not parse human-oriented text in automation.

## Do not initialize a fresh ledger over a retired codd ledger

`up` refuses to run when the database has a `codd.sql_migrations` (or legacy `codd_schema.sql_migrations`) ledger and native pg-migrate history is absent or empty. Running there would initialize a fresh ledger and re-plan every migration against a database that already has the objects.

Import the codd history first. `--allow-fresh-ledger-over-codd` overrides the refusal and applies only to `up`; use it exclusively when a fresh native ledger over the retired codd ledger is genuinely what you want. See [Codd Transition](./codd-transition.md).

## Prove the plan reached each replica

Applying migrations from a deployment job does not stop an application replica from starting before that job reaches its database. Every replica should call `missingMigrations` at boot and refuse to serve until `handshakePassed` holds. The check is a read-only status query, safe to run from every process. See [runtime assembly](../keiro/runtime-assembly.md).

## Treat `Running` after a crash as ambiguous

A crash during nontransactional work can leave its database effect absent, partial, or complete while the ledger says `Running`. Do not blindly rerun it and do not edit the ledger.

Back up, quiesce competing writers, inspect PostgreSQL catalogs and application state, and retain the evidence. Then choose exactly one confirmed repair with a non-empty reason: mark applied only if the intended effect is complete, or retry only when the current state makes retry safe. Repair appends an audit row recording the operation, old and new status, reason, role, runner version, and time.

## Respect the non-goals

pg-migrate has no down migrations, automatic execution retry, arbitrary repair, arbitrary runtime Haskell discovery, runtime filesystem discovery, or whole-database schema-snapshot comparison. Recovery is forward-only. A runner that supports an older ledger schema refuses to touch a newer database rather than attempting a downgrade.

Live-schema comparison is a Keiro-owned gate layered on top, not a pg-migrate feature.

## Related Patterns

- [The pg-migrate Model](./pg-migrate-model.md)
- [Migration Authoring](./authoring.md)
- [Migration Testing](./testing.md)
- [Codd Transition](./codd-transition.md)
