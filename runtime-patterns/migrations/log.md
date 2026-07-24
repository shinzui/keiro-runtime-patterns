# migrations Update Log

## 2026-07-23
* **Update**: Operations documents the `verify-schema` live-object gate, the codd-ledger preflight on `up`, and the per-replica startup handshake
* **Update**: Authoring requires the three-file review diff (SQL, manifest, lockfile) and the qualified-DDL body lint
* **Update**: Testing moves the integrity gates into the default build and documents explicit expected-schema regeneration
* **Update**: The pg-migrate model records the `RecompilePlugin` limit and the compile/review/deploy integrity layers
* **Update**: Service packages guard startup with `missingMigrations` against the shipped plan
* **Update**: Codd transition records the `up` refusal and the frozen cutover lockfile
* **Migration**: Adopted the OKF pattern-catalog profile for migration guidance
