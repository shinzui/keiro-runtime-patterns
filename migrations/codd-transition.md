# Codd to pg-migrate Transition

**Import persistent history into the new ledger without replaying DDL, and claim only the evidence strength the old database can prove.**

Use this explainer to understand the fleet’s one-time transition from Codd. It is context for current migration ownership, not a production migration runbook.

## Why the model changed

Codd keyed applied migrations by filename alone. pg-migrate uses component-local durable identities, exact payload checksums, explicit dependencies, and one application-owned plan. Kiroku and Keiro moved first; their native SQL files gained ordered `0001`-style names, and Keiro relocated framework tables from schema `kiroku` to its dedicated `keiro` schema.

The current runtime has one pg-migrate ledger for the Kiroku, Keiro, pgmq, and service components. Codd tooling remains only behind Keiro’s off-by-default `legacy-codd-tools` flag.

## Import history, never reapply it

A database with real application data cannot be dropped and rebuilt merely to change migration runners. The cutover reads Codd’s ledger and writes equivalent pg-migrate migration and audit rows. It does not execute the target migration actions or replay DDL.

The operation is one-time, forward-only, and performed while legacy writers are quiesced. After import, strict pg-migrate verification must explain the complete target history before new migrations run.

## State evidence honestly

Use `SamePayload` only when manifest-backed checksums and reviewed source bytes prove the target migration payload is the same payload represented by the Codd history. Use `EquivalentState` when the old checksum-blind workflow allowed a legitimate rewrite and a read-only state validator proves the target database state instead. Never upgrade validator-backed equivalence into a checksum claim.

`Kiroku.Store.Migrations.History.Codd` is the worked example: it maps the seven historical Codd filenames to native `0001` through `0007` identities with `SamePayload` evidence. Later native migrations do not need legacy mappings.

## Use the cohort procedure for production

For an old-cohort production database, use the `cohort-migrate` agent skill. That procedure inventories the cohort, restores a clone, composes the exact remediation, proves preservation and verification on the clone, and only then produces the production action. Do not improvise from this explainer against a live database.

## Related Patterns

- [Migration Operations](./operations.md)
- [The pg-migrate Model](./pg-migrate-model.md)
- [Migration Testing](./testing.md)

