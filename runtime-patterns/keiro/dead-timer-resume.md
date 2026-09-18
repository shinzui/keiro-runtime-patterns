---
type: Standard
title: "Dead timer inspection and guarded resume"
description: "Reading parked timers with bounded reason-filtered pages, resuming one under an expiring token claim, and the migration 0032 writer rollout and rollback order"
timestamp: 2026-09-18T04:30:00Z
generated:
  by: process:claude-code
  at: "2026-09-18T04:30:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-dead-timer-resume
tags: [keiro, timers, dead-timer-resume]
status: current
---

# Dead timer inspection and guarded resume

**Resume a Dead timer only through `claimDeadTimer` and its opaque claim, after the consumer has authorized the work, and only once every timer writer runs Keiro 0.16 or later.**

Since Keiro 0.16.0.0, `Dead` is not strictly terminal. A consumer can read parked timers with their stored reasons and deliberately resume one under the original timer identity, payload, and attempt history. The storage lease fences stale owners; it does not authorize the work, cancel an external call already in flight, or make the effect exactly once. Ordinary timer operation stays in [process managers and durable timers](../messaging/process-managers.md).

## Roll out migration 0032 in order

Migration `0032` adds the paired nullable `resume_claim_token` and `resume_lease_until` columns to `keiro.keiro_timers`, constrained to rows in `firing`. The columns are additive, but mixed writers are unsafe: an older binary does not enforce the token exclusions and can complete, cancel, or requeue a guarded claim.

1. Stop or drain every old timer writer: timer workers, process-manager and workflow hosts, operations consoles, and any custom SQL writer.
2. Apply the normal migration flow, including `0032`.
3. Deploy every upgraded writer.
4. Only then enable foreground resume.

Roll back in the reverse order: disable foreground resume, then drain or recover every guarded claim, then start an older writer. Never clear claims with ad hoc SQL, reset attempt counts, or drop and recreate the table.

## Inspect before claiming

Use `lookupTimerInspection` for one timer in any state and `findDeadTimers` for parked work. Both are read-only, take no row-claim locks, and return `TimerInspection`: the original `TimerRow` plus the full nullable `lastError`. `NULL` and empty text stay distinct.

- Filter with `DeadTimerFilter`: an optional exact `processManagerName` and a `TimerReasonFilter` of `AnyTimerReason`, `ReasonAbsent`, `ReasonExact`, or `ReasonPrefix`. Matching is case-sensitive and literal; `%`, `_`, and `\` are ordinary characters. `anyDeadTimer` selects everything.
- Request 1 to 100 rows with `DeadTimerPageRequest`. Any other size is `InvalidDeadTimerPageSize` before database access; nothing is clamped.
- Continue from `nextAfterTimerId` only. Order is ascending UUID, not chronological. Pages observe current eligibility, not a snapshot, so a row that becomes eligible behind the cursor is not revisited. Restart without a cursor when the filter changes.
- The page limit bounds returned rows, not database search cost.

Neither read authorizes disclosure. The owner label is not an authorization credential. Decode the payload and check fresh permissions before rendering, and keep following the continuation even when authorization empties a whole page.

## Claim with exact guards

Build a `DeadTimerClaimRequest` with the timer id, the mandatory exact `processManagerName`, the non-NULL literal `expectedReason`, an explicit total `maxAttempts` ceiling, and `leaseSeconds` between 1 and 2147483647. Invalid ceilings and leases return `TimerResumeError` without touching the database.

Before calling `claimDeadTimer`, decode the original payload, classify the reason, recheck authorization, and establish session or downstream availability. A refused preflight or a claim that returns `Right Nothing` consumes no attempt. A successful claim increments `attempts` exactly once and moves the row to `firing` under a fresh token.

Treat an ambiguous claim response as no ownership. Inspect and recover rather than executing optimistically. Raising `maxAttempts` is an explicit policy decision, never an automatic history reset.

## Work under the claim

Execute only after receiving a `TimerResumeClaim`, and outside the SQL transaction.

- `renewTimerResume claim seconds` extends the lease from database time and keeps the token. `False` means ownership is lost; an expired claim cannot be revived. `resumeClaimLeaseUntil` is the claim-time snapshot and does not move on renewal, so schedule renewals by the requested interval.
- `completeTimerResume claim eventId` marks the timer `fired`. Never report success when it returns `False`.
- `parkTimerResume` returns the row to `Dead`, keeping the original reason and the incremented attempts. Use it after post-claim session loss or a transient failure; that attempt is spent.
- `cancelTimerResume` abandons the work as the current owner.

On lost ownership, stop local work where possible and do not report completion. The lease cannot stop an external call that has already started. Give the work a stable identity and deduplicate its result in the consumer: execution is at-least-once.

## Recover expired claims

`recoverExpiredTimerResumes` returns every expired guarded claim directly to `Dead` with its reason, payload, due time, and attempt history intact. It never makes a row `Scheduled`, so a resumed timer never re-enters background firing.

Every ordinary timer worker pass runs this recovery, even with `requeueStuckAfter = Nothing`; that option now disables only ordinary stale-claim requeue. A host that performs only foreground resume must call `recoverExpiredTimerResumes` periodically itself, and before every discovery or resume pass.

## Respect the ID-only exclusions

`markTimerFired`, `cancelTimer`, `cancelTimerTx`, `deadLetterTimer`, and stale requeue refuse any row that carries a resume token, including an expired claim still awaiting recovery. Old handles cannot mutate a replacement claim, which always has a new token. Do not bypass these exclusions with direct SQL; route operator repair through the [operations console](operations-console.md), whose ID-only timer commands inherit the same refusal.

## Related Patterns

- [Process managers and durable timers](../messaging/process-managers.md)
- [Keiro operations console](operations-console.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Migration operations](../migrations/operations.md)
