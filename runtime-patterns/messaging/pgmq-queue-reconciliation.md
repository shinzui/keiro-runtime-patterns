---
type: Standard
title: "PGMQ queue lifecycle and reconciliation"
description: "Validated durable queue names, additive startup reconciliation, truthful drift reports, notification recovery, and PGMQ 1.13 schema, partition premake, and retry classification in pgmq-hs 0.6"
timestamp: 2026-09-18T05:30:00Z
generated:
  by: process:claude-code
  at: "2026-09-18T05:30:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-pgmq-queue-reconciliation
tags: [messaging, pgmq-queue-reconciliation]
status: current
---

# PGMQ queue lifecycle and reconciliation

**Declare queues with validated names, reconcile additively, and turn every reported drift into an operator decision rather than a destructive startup repair.**

These rules target the released pgmq-hs 0.6 package family (0.6.1.0). Upgrade `pgmq-core`, `pgmq-hasql`, `pgmq-effectful`, `pgmq-config`, and `pgmq-migration` together with bounds `>=0.6 && <0.7`; Keiro 0.17 and `shibuya-pgmq-adapter` 0.16 require that family.

Crossing from 0.5 breaks two records. `QueueMetrics` gains `defaultPartitionLength :: Maybe Int64`, and `PartitionConfig` gains `premake :: Maybe Int32`; positional constructors and patterns must supply both. The family accepts `effectful-core` `^>=2.6 || ^>=2.7`; on 2.7 use 2.7.1.1 or newer, because 2.7.0.0 slows every dynamically dispatched queue operation. Keiro 0.17 and adapter 0.16 still bound `effectful-core` below 2.7, which decides the version a Keiro service resolves.

## Migrate the schema before creating queues

`pgmq-migration` 0.6 upgrades native PGMQ to 1.13 through append-only migrations `0004`–`0006`, preserving existing queue data and the imported 1.11 checksum contract. Apply every pending migration before admitting queue-creation traffic. Grouped reads, including grouped-head reads, need 1.12; explicit premake and `defaultPartitionLength` need 1.13.

## Freeze a valid queue identity

Construct every `QueueName` through `parseQueueName`, including JSON and configuration input. A name must be non-empty, at most 47 characters, and contain only lowercase ASCII letters, digits, and underscore. Do not lowercase or otherwise normalize an invalid input.

Mixed case is data corruption risk, not style: pgmq stores the caller's spelling in metadata while deriving lowercased physical tables, so two logical names can alias one table. Before upgrading a database that contains mixed-case metadata, run the transactional remediation documented by `mori://shinzui/pgmq-hs/docs/queue-configuration`; never update or delete `pgmq.meta` rows by hand because its child foreign keys cascade.

Use strict `listQueues` when every row is expected to be owned and valid. Use `listQueuesUnvalidated` for shared-database observation and reconciliation so one foreign queue cannot make the application's startup decoder fail. Never pass an unvalidated observed name into a typed queue operation without parsing it.

## Reconcile only what startup can prove safely

Declare queue type, notifications, FIFO index, and topic bindings in `QueueConfig`, then run `ensureQueuesReport` or its Effectful sibling at startup. Read and act on every `ReconcileAction`.

The reconciler is additive. It may create a missing queue, notification row, FIFO index, or topic binding. Its only mutation of existing configuration is applying a changed notification throttle. It must not drop or recreate a queue to change its type: `DetectedQueueTypeDrift` is a startup/operator failure that preserves messages.

`pgmq.list_queues()` exposes only standard, unlogged, or partitioned shape. Partition interval, retention, and premake are not drift-checked. Record and verify those separately when they are operationally load-bearing. `SkippedFifoIndex` and `CreatedFifoIndex` now report the observed catalog truth; do not infer action from intent.

`PartitionConfig.premake` applies only at creation. `Nothing` uses the server default of four premade partitions and works on 1.12; `Just n` requires 1.13 and `n >= 1`. Changing it for an existing queue neither reconfigures `pg_partman` nor reports drift.

## Watch default-partition spill

On 1.13, `defaultPartitionLength` is a planner estimate of rows that spilled into the queue and archive default partitions. Treat a positive value as a maintenance alert. `Nothing` means unavailable (1.12) or inapplicable (ordinary queues); never read it as zero, and expect a zero estimate to lag writes until statistics refresh. Upgrading does not drain defaults: run the upstream recovery sequence (`partition_data_proc` outside a transaction for each affected queue and archive, maintenance, then `ANALYZE`).

## Treat notifications as hints

Use `notifyChannelName`; the channel is not a string applications should assemble. LISTEN/NOTIFY is fire-and-forget and throttled, so every consumer needs a poll fallback.

A missing throttle means the documented 250 ms default. Reconciliation must compare `Nothing` with a stored 250 as equal and leave an unchanged row alone; re-enabling resets `last_notified_at`. A real throttle change uses `UpdatedNotifyThrottle` and makes the next insert notify immediately.

Install the `pgmq-migration` native component when the application owns the schema. Its crash-safety and locking migration makes notification delivery fail open after an unlogged throttle table is truncated by crash recovery and serializes concurrent enable calls. On a stock upstream extension without that component, concurrent multi-replica reconcile can still surface SQLSTATE 42710; coordinate startup or classify that environment explicitly.

## Distinguish lost races from infrastructure failure

`changeVisibilityTimeout` and `setVisibilityTimeoutAt` return `Maybe Message`. `Nothing` means the row was already deleted, archived, or popped; settle it as a lost race, not a database outage.

`isTransient` retries acquisition, networking, connection-session failures, SQLSTATE 40001, 40P01, 55P03, 57P01, 57P02, 57P03, and SQLSTATE class 53. Authentication, compatibility, decode/row-count, script, missing-type, driver, and every other statement failure remain permanent. Branch on this classifier rather than restating a partial list.

## Related Patterns

- [Typed PGMQ jobs](pgmq-jobs.md)
- [Transport selection](transport-selection.md)
- [Messaging gotchas](gotchas.md)
- [Migration authoring](../migrations/authoring.md)
