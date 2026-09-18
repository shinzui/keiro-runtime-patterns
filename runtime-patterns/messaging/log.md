# messaging Update Log

## 2026-09-18
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Define delegated intake, producer identity, process reaction, guarded claim, and grouped-head FIFO terms.
* **Update**: State the mkDelegatedRetryContext ceiling/attempt order and its runInboxDelegatedWithRetries use.
* **Update**: Restore FIFO-index reporting to the drift section and correct the effectful-core bound.
* **Update**: Require a consumers-first FifoHeads rollout after the PGMQ 1.12 schema migration.
* **Update**: Specify conflict condemnation and halting, out-of-SQL recording, isolation retries, retention horizon, replay comparison rules, and the Keiro.Outbox.Identity selector-ambiguity upgrade step.
* **Update**: Route pgmq-hs 0.6, FIFO-heads jobs, the reaction runner, and delegated inbox intake.
* **Update**: Add FIFO-heads, DLQ-inspection, partition-retention, frozen producer identity, reaction-runner, and delegated-inbox traps; move PGMQ claims to 0.6 and renumber.
* **Update**: Add delegated intake (runInboxDelegated\*, Keiro.Inbox.Delegated), its receipt contract, caller-owned retry and DLQ, and the cutover as an identity change.
* **Update**: Add the Keiro.ProcessManager.Reaction runner and its drain-first identity migration, cancelTimerTx, expired-resume recovery in every timer pass, ID-only exclusions, and resumable Dead timers.
* **Update**: Distinguish the grouped-head FIFO failure barrier from the legacy fill strategies.
* **Update**: Move to pgmq-hs 0.6: PGMQ 1.13 migrations 0004-0006, breaking QueueMetrics and PartitionConfig fields, creation-only premake, default-partition spill monitoring, and the effectful-core range.
* **Update**: Require job ordering, add FIFO-heads grouped-head consumption, guarded DLQ purge and id-exact archiving, header-preserving redrive, and validated partition retention for keiro-pgmq 0.17.
* **Update**: Treat messageId as opaque and derive producer identity deterministically; deprecate mintIntegrationEvent for freshIntegrationEvent.
* **Update**: Adopt deterministic versioned producer identity, typed enqueue outcomes, conflict handling, the random-ID cutover, and verbatim content\_type publication.

## 2026-09-06
* **Update**: Classify Store 0.8 transaction aborts as AckRetry in process-manager and router workers.
* **Update**: Route publication rejection and atomic finalization through the outbox standard.
* **Update**: Handle terminal rejection, atomic conditional finalization, schema rollout, and retained audit evidence.
* **Update**: Adopt adapter 0.5.1.1 and preserve application dead-letter codes in structured JSON.
* **Update**: Distinguish terminal publication rejection from retryable destination failure.

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
