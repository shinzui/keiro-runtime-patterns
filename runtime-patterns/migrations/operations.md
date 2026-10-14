---
type: Runbook
title: "Migration Operations"
description: "Operating verify, verify-schema, status, and repair; the codd preflight; Running after a crash needs audited repair"
timestamp: 2026-10-14T22:01:17Z
generated:
  by: process:codex
  at: "2026-10-14T22:01:17Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/migrations-operations
tags: [migrations, operations]
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
      Model technical-accuracy review against the mori-resolved keiro-migrations, kiroku-store-migrations, and pg-migrate source and CLIs; changes requested: the every-command-supports-JSON claim excludes verify-schema, and the released import-codd-history command is never named.
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
      Model re-review of the correction against the keiro-migrate CLI: JSON support is scoped per command and import-codd-history is named with its flags.
---

# Migration Operations

**Review the complete embedded plan, apply it in one deployment job, and repair nontransactional ambiguity only from audited evidence.**

Use this runbook to inspect, apply, verify, or repair a service’s pg-migrate plan. It distinguishes safe read-only commands from state-changing operations and defines the crash-recovery boundary.

## Use the service executable

Use JSON as the stable automation contract: every command below accepts `--json` except `verify-schema`, which currently emits text only.

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
| `import-codd-history` | yes | Import verified codd history into the native ledger before the first `up`. |

Run `plan`, `status`, and strict `verify` against the intended database and role before deployment. Pending migrations make strict verification fail before `up`; this is expected. After `up`, strict verification must succeed.

## Verify the ledger and the live schema separately

The two gates answer different questions and neither substitutes for the other. Run both around every deployment, restore, and cutover.

`verify` compares the embedded plan with pg-migrate’s durable ledger. It detects checksum, identity, position, kind, transaction-mode, status, gap, and unknown-row problems. It does **not** look at live database objects, so a clean ledger can still sit over a hand-altered schema.

`verify-schema` closes that hole for the framework schema. It compares the live tables, columns, constraints, and indexes in the `keiro` and `keiro_read` schemas against a checked-in, sorted expected snapshot, reporting each missing, unexpected, or changed object and exiting non-zero on any drift.

Know its boundaries. The snapshot targets PostgreSQL 18. Roles, grants, database settings, and standalone sequence properties are out of scope; sequence-backed column defaults remain covered as column definitions. It is a Keiro-maintained representation, not a general schema-diff engine. It currently emits text only, while the pg-migrate commands also accept `--json` as the stable automation contract.

Record the artifact identity, target, role, timestamps, and command output. Do not parse human-oriented text in automation.

## Do not initialize a fresh ledger over a retired codd ledger

`up` refuses to run when the database has a `codd.sql_migrations` (or legacy `codd_schema.sql_migrations`) ledger and native pg-migrate history is absent or empty. Running there would initialize a fresh ledger and re-plan every migration against a database that already has the objects.

Import the codd history first with `keiro-migrate import-codd-history`; it verifies the checked-in codd source evidence under advisory locking, requires `--reason` and `--confirm`, and supports `--json`. `--allow-fresh-ledger-over-codd` overrides the refusal and applies only to `up`; use it exclusively when a fresh native ledger over the retired codd ledger is genuinely what you want. See [Codd Transition](./codd-transition.md).

## Prove the plan reached each replica

Applying migrations from a deployment job does not stop an application replica from starting before that job reaches its database. Every replica should call `missingMigrations` at boot and refuse to serve until `handshakePassed` holds. The check is a read-only status query, safe to run from every process. See [runtime assembly](../keiro/runtime-assembly.md).

## Stop timer writers before Keiro `0032`

Keiro `0032` is the exception to deploying code against an already-migrated schema. Its guarded-resume columns are additive, but old binaries do not enforce their exclusions. Stop or drain every timer writer — workers, process-manager and workflow hosts, consoles, custom SQL — then run `up`, deploy every upgraded writer, and only then enable foreground resume. To roll back writers, disable resume and drain or recover guarded claims first. See [dead timer resume](../keiro/dead-timer-resume.md).

## Treat `Running` after a crash as ambiguous

A crash during nontransactional work can leave its database effect absent, partial, or complete while the ledger says `Running`. Do not blindly rerun it and do not edit the ledger.

Back up, quiesce competing writers, inspect PostgreSQL catalogs and application state, and retain the evidence. Then choose exactly one confirmed repair with a non-empty reason: mark applied only if the intended effect is complete, or retry only when the current state makes retry safe. Repair appends an audit row recording the operation, old and new status, reason, role, runner version, and time.

## Recover the withdrawn Kiroku `0010` payload precisely

`kiroku-store-migrations` 0.4.0.0 corrects an unqualified `uuidv7()` default in `0010`. The withdrawn 0.3.2.0/0.3.2.1 payload fails in an ordinary PostgreSQL 17 upgrade session; on PostgreSQL 18 or a fresh PostgreSQL 17 bootstrap it may already have applied. Choose the recovery from durable history, not the server major alone.

- If `kiroku/0010` is absent, leave the ledger alone and apply the corrected pending plan.
- If it was applied with the withdrawn checksum, back up the database and record the current ledger and schema evidence. Obtain the release-owned script from `mori://shinzui/kiroku`, project-relative path `kiroku-store-migrations/ledger-fixups/2026-08-16-rebaseline-0010-checksum.sql` (artifact-level URI pending). Review and run it once before the next `up`; configure its ledger-schema lookup if the application does not use `pgmigrate`.
- If the checksum is already corrected, no rebaseline is needed. Any other checksum is an unexplained divergence; investigate rather than widening the script's match.

The script transaction updates only the `kiroku/0010` row carrying the exact withdrawn SHA-256. It is idempotent and changes no schema. This producer-supplied recovery is a narrow exception for a payload that prevents its own forward fix from running; it is not a general `repair` operation or permission to rewrite migration history.

After rebaselining, run the complete service plan through ordinary `up`, including Kiroku `0011`. That forward migration publishes `kiroku.uuidv7()` where needed and rebinds the lease default; changing the checksum alone does neither. Require strict `verify`, inspect the qualified function and stored lease default, and run the service's live-schema checks. Retain the before/after evidence with the deployment record.

## Respect the non-goals

pg-migrate has no down migrations, automatic execution retry, arbitrary repair, arbitrary runtime Haskell discovery, runtime filesystem discovery, or whole-database schema-snapshot comparison. Recovery is forward-only. A runner that supports an older ledger schema refuses to touch a newer database rather than attempting a downgrade.

Live-schema comparison is a Keiro-owned gate layered on top, not a pg-migrate feature.

## Upgrade the Kiroku store in order

Plan a forward cutover to Store 0.11.0.0 / migrations 0.7.1.0, as required by Keiro 0.21. Rehearse the composed plan on a restored persistent database.

1. **0012 (Store 0.9 boundary): stop every old appending process.** The migration backfills `$all` row categories, installs a check constraint and builds the category-read index in one transaction. It blocks writes while running; plan a maintenance window and run `VACUUM (ANALYZE) kiroku.stream_events` afterwards. Old 0.8 writers fail against the new constraint; 0.9+ writers fail against the old schema. There is no mixed-writer rolling upgrade across this boundary.
2. **0013/0014 (Store 0.10 boundary): stop subscription workers.** 0013 derives persisted group size from existing members; incomplete legacy groups may require explicit resize. 0014 replaces unused `stream_name` with target-binding columns. Review legacy target adoption and configure validated capacities before restart. Startup refuses inconsistent topology or target bindings; use the [public resize/rebind operations](../kiroku/subscriptions.md), not private SQL repairs.
3. **0015 (Store 0.11 inspection): budget another write pause.** Its partial byte-ordered stream-name index is built transactionally. Size the window on representative data; published practical performance acceptance does not remove index-build blocking or ongoing write cost.

Apply the complete dependency-first service plan and run strict ledger verification plus live schema checks before enabling workers. No Keiro migration payload changed in 0.21; this does not exempt an older service from these Kiroku changes.

## Allow only registered runtime binding-view additions

Keiro 0.21's `verifyExpectedSchema` uses `compareSchemaSnapshotWithManaged` to allow live binding-view keys recorded with `managed_by = 'keiro'`. The pure `compareSchemaSnapshot` remains unchanged. Read permission on `keiro.keiro_managed_read_objects` plus `USAGE` on its schema is required; absent/unreadable registry state supplies no exemptions. Missing or changed migration-owned objects and unregistered additions remain drift. A registry match does not compare runtime-only view definitions or definition hashes; verify those through catalog reconciliation.

## Related Patterns

- [The pg-migrate Model](./pg-migrate-model.md)
- [Migration Authoring](./authoring.md)
- [Migration Testing](./testing.md)
- [Codd Transition](./codd-transition.md)
- [Dead timer resume](../keiro/dead-timer-resume.md)
