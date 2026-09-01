# messaging Update Log

## 2026-09-01
* **Update**: Require custom service-owned dedupe identities to remain nominal and TypeID-backed until the inbox boundary
* **Update**: Keep outbox identities nominal and distinguish prescribed UUIDv5 derivation from allocated TypeID-v7 identity
* **Update**: Keep envelope primitives at the boundary and payload domain values nominal and TypeID-backed

## 2026-08-14
* **Update**: Add stuck-timer repair by classification through the operations console
* **Update**: Route the console PGMQ dead-letter read, redrive, archive, and purge commands
* **Update**: Route the console inbox inspection, retention, and mark-failed commands
* **Update**: Route the console outbox inspection, stuck-row reclaim, and retention commands
* **Update**: Route application dead-letter codes from the Shibuya processing standard
* **Update**: Move the process-manager release claim to the 0.12.0.0 set
* **Update**: Move the supervised-runner claim to Shibuya 0.9.0.0
* **Update**: Record the structured dead-letter reason fields written by shibuya-pgmq-adapter 0.14.0.0
* **Update**: Move adapter and Shibuya version claims to the 0.9 line and warn against per-message dead-letter code validation
* **Update**: Add application-defined dead-letter codes, total reason projections, and their telemetry boundary

## 2026-08-10
* **Added**: Add pgmq-hs 0.5 queue identity, reconciliation, notification, and retry rules.
* **Update**: Freeze UTF-8 deterministic ids and use bounded timer drains.
* **Update**: Connect Keiro jobs to validated PGMQ names and additive reconciliation.
* **Update**: Route pgmq-hs 0.5 queue lifecycle and reconciliation.
* **Update**: Correct pgmq-hs 0.5 retry classification and add reconciliation, VT-race, and notification traps.

## 2026-08-06
* **Migration**: Move the bundle to OKF v0.2: every concept gains a generated provenance mapping and restates its timestamp in UTC
* **Update**: Process-manager release claim moves to the current 0.11.0.0 set
* **Update**: PGMQ standard states that the spec fanout body and top-level dedupe key are descriptive-only

## 2026-07-31
* **Update**: Process-manager boundary now cites the released 0.5.0.0 line

## 2026-07-29
* **Update**: Process managers now name the released Keiro 0.4 boundary; re-reviewed and approved
* **Review**: Recorded a model technical-accuracy review for all eleven concepts; approved ten, changes requested for process-managers (standard pins itself to the Keiro 0.3 released boundary; 0.4.0.1 is current)

## 2026-07-23
* **Migration**: Adopted the OKF pattern-catalog profile for messaging guidance
