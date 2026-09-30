---
type: Standard
title: "PGMQ connection faults and retry budgets"
description: "What a PostgreSQL restart, backend termination, or TCP reset looks like to the runtime, how to size shibuya-pgmq-adapter poll and ack retry budgets, what exhaustion does under supervision, and how to keep enqueues idempotent under lost replies"
timestamp: 2026-09-30T21:30:00Z
generated:
  by: process:claude-code
  at: "2026-09-30T21:30:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/messaging-pgmq-connection-faults
tags: [messaging, pgmq, retries, connection-faults]
status: current
---

# PGMQ connection faults and retry budgets

**Bound every retry against PostgreSQL, size the budget to the outage you plan to survive, decide what exhaustion does before it happens, and treat a lost reply to an enqueue as a possible duplicate rather than as a failure.**

A connection fault is any event that ends a PostgreSQL connection while the runtime is using it: an immediate or crash restart of the server, `pg_terminate_backend` on the worker's backend, a TCP reset from a proxy or a failover, or an idle connection the server closed. These rules target the released pgmq-hs 0.6.1.1 family, `shibuya-pgmq-adapter` 0.16, and keiro-pgmq 0.17, and they state what those releases do rather than what a candidate promises.

## Know what the released classifier does with a lost connection

`Pgmq.Effectful.isTransient` is the only retry gate the adapter uses. In pgmq-hs 0.6.1.1 it retries acquisition timeouts, networking and unrecognised connection errors, connection-session failures, SQLSTATE 40001, 40P01, 55P03, 57P01, 57P02, 57P03, and class 53, and calls everything else permanent, as the [queue lifecycle standard](pgmq-queue-reconciliation.md) records.

A connection lost while a statement is in flight does not arrive as a connection error. The hasql driver reports only a failed send as a connection-session failure; a reply that never comes back is reported through the statement-error constructors, in one of two shapes. When the socket closes without a server message (immediate shutdown, TCP reset), the error is a server error whose SQLSTATE is the empty string. When the server sends its own fatal error and then closes (`pg_terminate_backend`, which sends 57P01), the driver receives a stray second result and reports `UnexpectedRowCountStatementError 1 1 1`. Both are permanent in 0.6.1.1, so the adapter does not retry the first in-flight failure at all; only the *next* operations are transient, because the dead pooled connection fails at send and a refused reconnect is a networking error. The defect is recorded as `mori://shinzui/pgmq-hs/okf/bug-reports/concepts/BUG-1`; the remediation request is `mori://shinzui/pgmq-hs/okf/improvement-requests/concepts/IR-4`; the fix is planned in `mori://shinzui/pgmq-hs/plans/26-classify-postgresql-disconnects-surfaced-as-statement-errors-as-transient` and is unreleased. The Kenshou scenarios `pgmq/effectful/concurrency/backend-termination-recovery`, `postgres-restart-recovery`, and `network-partition` in `mori://shinzui/keiro-runtime-kenshou` reproduce all three shapes and are declared known defects against BUG-1 until a release carries the fix.

Do not write service code against the unreleased classifier or its planned `isAmbiguousReply` companion. This standard will be revised to cite the released version when it ships; until then the rules below hold for both the released and the fixed behaviour.

## Size the adapter budgets to the outage you plan to survive

`PgmqAdapterConfig` carries two independent budgets, `pollRetry` and `ackRetry`, both of type `PollRetryConfig` with `maxAttempts` (total attempts, including the first), `initialBackoff`, and `maxBackoff`. The adapter retries while `isTransient` holds and attempts remain, doubling the delay from `initialBackoff` and capping it at `maxBackoff`. `defaultPollRetryConfig` is five attempts, 0.1 s, and 5 s, which waits 0.1 + 0.2 + 0.4 + 0.8 = 1.5 s in total before giving up. The cumulative wait is the sum of `min(initialBackoff * 2^k, maxBackoff)` for `k` from 0 to `maxAttempts - 2`; compute it and write it beside the configuration.

Size the budget from the outage, not from the defaults. A crash-recovery restart of a small cluster completes in well under a second (Kenshou measured about 360 ms on PostgreSQL 17 and 18), but a planned failover, a major-version restart, or a slow crash recovery takes tens of seconds. Add one attempt per pooled connection: hasql-pool returns a connection that died mid-statement to the pool, and each such connection costs one transient failure at its next use before it is evicted. Ten attempts at 0.1 s doubling to a 5 s cap wait 21.3 s; that survives a routine failover and still fails fast on a database that is gone.

Give `ackRetry` at least the poll budget. Ack retries wrap deletes, archives, visibility-timeout changes, and lease extension, all of which are safe to repeat, and an exhausted ack budget makes the finalizer throw. Shibuya then retries the already-resolved decision after 10 ms, 50 ms, and 250 ms and halts the processor on exhaustion, as the [processing guide](shibuya-processing.md) describes; the halted message returns on visibility-timeout expiry, so nothing is lost, but the worker is down.

keiro-pgmq builds the adapter configuration from `JobTuning` and the job's `RetryPolicy` and does not set `pollRetry` or `ackRetry` (verified against keiro source on 2026-09-30). A Keiro job worker therefore runs at the adapter defaults, and its resilience to an outage longer than about 1.5 s comes from supervision and process restart, not from retries. Raise a keiro-pgmq improvement request when a service's outage horizon exceeds that; do not fork the processor wiring to reach the fields.

## Decide what exhaustion does before it happens

When the poll budget is exhausted the error is rethrown, the polling stream ends, and the processor fails; keiro-pgmq propagates this visibly through Shibuya supervision rather than completing the worker silently. What happens next is the supervision strategy. Under `IgnoreFailures` the processor is marked failed in metrics and its siblings keep running, which means the queue silently stops being consumed until someone reads the metric. Under `StopAllOnFailure` every processor stops, the application exits, and the platform restarts it with a fresh pool.

Run PGMQ workers under `StopAllOnFailure` unless a supervisor of your own restarts the individual processor, and alert on the failed-processor metric either way. Pair the strategy with the restart and readiness rules in [Kubernetes deployment](../config/kubernetes-deployment.md) so an exhausted budget becomes a restart, not an idle pod. A process restart is the correct recovery for an outage longer than the budget; a budget large enough to never exhaust is a worker that never reports the database is gone.

## Keep enqueues idempotent under lost replies

Every keiro-pgmq `enqueue*` function is a bare `sendMessage` with no retry, and a producer that calls `Pgmq.Effectful.sendMessage` directly has the same exposure. Under a connection fault the insert can commit and the reply carrying its `MessageId` can still be lost. Re-sending then duplicates the message, whether the loop retried because the error was transient or because a human restarted the job.

- **Key idempotency on a producer-supplied identity, never on `MessageId`.** Derive a stable job identity from the triggering business fact, in the payload or a header, the way the [transactional outbox](outbox.md) derives its deterministic message identity, and make the handler idempotent on it. The [typed jobs standard](pgmq-jobs.md) already requires idempotent handlers because reads are leases, not exactly-once delivery; a duplicate enqueue is one more duplicate delivery that rule absorbs. The producer never learns the `MessageId` of a lost reply, so nothing can be keyed on it.
- **Route enqueues that must not duplicate at the queue through the outbox.** `publishClaimedOutbox` is transport-neutral: a publisher callback that calls `sendMessageWithHeaders` gives PGMQ enqueues the outbox's deterministic identity, attempt ceiling, and `PublishFailed` retry, and the consuming service deduplicates on the message identity.
- **Bound the producer's loop and make a lost reply sticky.** Cap attempts or set a deadline, because a server that stays down produces transient errors indefinitely. Once an enqueue's statement was sent and its reply was lost, later attempts reconcile (look the job up by its identity, or check the effect it was to produce) instead of sending again, and keep reconciling through further transient failures until the lookup succeeds or the bound is hit. When the released classifier gains `isAmbiguousReply`, gate that switch on it; until then treat any failure of an enqueue whose statement was sent as possibly committed.
- **Expect duplicates around dead-lettering too.** The one-shot `runJobOnce*` drain sends to the DLQ and deletes the main row as separate effects, so a fault between them leaves both copies, as the typed jobs standard records; the same identity-keyed idempotency covers it.

## Prove the budget with a fault test

Before raising a budget in production, run a fault test that terminates the worker's backend during a poll, restarts the server immediately, and resets the connection at the network layer, and assert that the worker resumes on the same pool within the configured budget without a process restart. The Kenshou scenarios named above do exactly this for the released cohort and record the recovery time per run; run them against the candidate cohort and read the `same-pool-recovers` and transience checks rather than trusting the arithmetic.

## Related Patterns

- [Typed PGMQ jobs](pgmq-jobs.md)
- [PGMQ queue lifecycle and reconciliation](pgmq-queue-reconciliation.md)
- [Shibuya processing](shibuya-processing.md)
- [Transactional outbox](outbox.md)
- [Kubernetes deployment](../config/kubernetes-deployment.md)
- [Messaging gotchas](gotchas.md)
