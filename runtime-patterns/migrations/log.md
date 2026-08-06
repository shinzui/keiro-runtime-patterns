# migrations Update Log

## 2026-08-06
* **Migration**: Move the bundle to OKF v0.2: every concept gains a generated provenance mapping and restates its timestamp in UTC

## 2026-07-29
* **Update**: Operations now scope JSON output per command and name import-codd-history for the codd preflight; re-reviewed and approved
* **Update**: Testing now names hasql's SessionError and the template-database suite fixture convention; re-reviewed and approved
* **Review**: Recorded a model technical-accuracy review for all seven concepts; approved five, changes requested for operations (JSON-everywhere claim excludes verify-schema; import-codd-history never named) and testing (UsageError where hasql 1.10 returns SessionError)

## 2026-07-23
* **Update**: Operations documents the `verify-schema` live-object gate, the codd-ledger preflight on `up`, and the per-replica startup handshake
* **Update**: Authoring requires the three-file review diff (SQL, manifest, lockfile) and the qualified-DDL body lint
* **Update**: Testing moves the integrity gates into the default build and documents explicit expected-schema regeneration
* **Update**: The pg-migrate model records the `RecompilePlugin` limit and the compile/review/deploy integrity layers
* **Update**: Service packages guard startup with `missingMigrations` against the shipped plan
* **Update**: Codd transition records the `up` refusal and the frozen cutover lockfile
* **Migration**: Adopted the OKF pattern-catalog profile for migration guidance
