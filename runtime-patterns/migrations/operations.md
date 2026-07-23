---
type: Runbook
title: "Migration Operations"
description: "Operating verify, status, and repair; verify is ledger-versus-plan; Running after a crash needs audited repair"
timestamp: 2026-07-22T09:54:51-07:00
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

Run `plan`, `status`, and strict `verify` against the intended database and role before deployment. Pending migrations make strict verification fail before `up`; this is expected. After `up`, strict verification must succeed.

## Understand what verification proves

`verify` compares the embedded plan with pg-migrate’s durable ledger. It detects checksum, identity, position, kind, transaction-mode, status, gap, and unknown-row problems. It does not compare the live database schema to a declarative schema snapshot.

Record the artifact identity, target, role, timestamps, and command output. Do not parse human-oriented text in automation.

## Treat `Running` after a crash as ambiguous

A crash during nontransactional work can leave its database effect absent, partial, or complete while the ledger says `Running`. Do not blindly rerun it and do not edit the ledger.

Back up, quiesce competing writers, inspect PostgreSQL catalogs and application state, and retain the evidence. Then choose exactly one confirmed repair with a non-empty reason: mark applied only if the intended effect is complete, or retry only when the current state makes retry safe. Repair appends an audit row recording the operation, old and new status, reason, role, runner version, and time.

## Respect the non-goals

pg-migrate has no down migrations, automatic execution retry, arbitrary repair, arbitrary runtime Haskell discovery, runtime filesystem discovery, or whole-database schema-snapshot comparison. Recovery is forward-only. A runner that supports an older ledger schema refuses to touch a newer database rather than attempting a downgrade.

## Related Patterns

- [The pg-migrate Model](./pg-migrate-model.md)
- [Migration Authoring](./authoring.md)
- [Codd Transition](./codd-transition.md)
