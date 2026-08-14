---
type: Standard
title: "Targeted stream-scoped projection repair"
description: "Declaring a StreamScopedReplay policy and repairing one stream's projection rows under admission limits without a group rebuild"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-stream-scoped-repair
tags: [keiro, stream-scoped-repair]
status: current
---

# Targeted stream-scoped projection repair

**Repair one stream's projection rows through a declared `StreamScopedReplay` policy; never hand-patch a serving target and never take a whole group offline for one bad stream.**

A group rebuild fences every reader and writer of the group. When exactly one stream's rows are wrong — a fixed handler bug that damaged one tenant, one aggregate, one correlation — that blast radius is the wrong tool. Targeted reprojection repairs the affected stream against the persisted serving revision inside one transaction, and refuses whenever it cannot prove the repair is complete.

## Declare the policy in the projection revision

A projection is repairable only if its `ProjectionRevision` declares a `StreamScopedReplay` for it. The policy is application-owned and names, with stable identity and positive version for each callable:

- `streamOwnedTargets` — exactly the projection's owned targets, no more and no fewer;
- `clearStreamRows` — deletes this stream's rows and returns one `StreamClearCount` per declared target;
- `replayStreamEvent` — applies one recorded event, returning whether it changed rows or a typed decode failure;
- `verifyStreamRows` — the application's post-repair semantic check;
- `affectedAsyncDedup` — exactly the dedup identities of the projection's async handlers.

Catalog validation rejects a duplicate policy for one projection, an unknown projection, a cross-group policy, a target set that differs from the projection's owned targets or from the revision's provisioned targets, a dedup set that differs from the projection's async handlers, and blank or unversioned identities. A projection with no declared policy is not repairable, and asking for one refuses rather than falling back to a group rebuild.

Keiro owns admission, locking, history completeness, ordering, rollback, and redelivery evidence. The application owns row selection, event semantics, and verification.

## Admit the work before fencing anything

Every repair carries a positive `maxEvents` admission limit. The runner locks the stream's history first, compares the locked event count against that limit, and refuses an oversized stream **before** taking the group-wide writer fence, so a rejected request never interrupts serving traffic. `keiro-ops rebuild reproject-stream` defaults `--max-events` to 1000 and rechecks it against locked stream metadata; review the previewed event count rather than raising the limit reflexively.

The lock order is fixed: stream-history guard, then the exclusive group fence. Catalog command writers append first and take the group's shared lock in their continuation, so this order lets an already-appended writer finish instead of forming a row-lock cycle. Do not reproduce the operation with hand-written SQL in the other order.

## Treat every refusal as a stop, not a retry

The runner refuses, condemns the transaction, and leaves the serving rows untouched when it observes:

- a soft-deleted stream, a stream with a `truncateBefore` marker, or history that does not read forward to the locked version — a truncated or partially deleted prefix cannot produce a complete repair;
- an event whose original stream or version differs from this stream's — linked events are not this stream's history;
- an active rebuild on the group, an unregistered group, a group whose reads or writes are unavailable, or group-slice drift against the mounted catalog;
- a missing or invalid serving revision binding, or a group still on the unversioned binding;
- clear evidence that omits a declared target, repeats one, reports a negative count, or names a target absent from the revision's physical map;
- a decode failure, a clear failure, or a failed application verification.

None of these are transient. Repair the named cause; a repair that "mostly worked" is exactly the outcome this protocol exists to prevent.

## Know what the repair does not touch

The repair backfills ordinary async dedup keys for every replayed event so the same events are not applied twice after the transaction commits. It **leaves subscription checkpoints unchanged** — the subscription is still where it was, and no unrelated stream is redelivered.

Keiro enforces that nothing outside the named projection's owned targets is written: clear evidence must name exactly the declared target set, and those targets must belong to the projection under the revision's physical map. Confining the clearer and the replay closure to **this stream's rows within those targets** is the application's obligation — a clearer that deletes by target rather than by stream turns a targeted repair into an unfenced group truncation. Other projections in the group are not cleared, replayed, or verified. If the damage spans streams or projections, that is a group rebuild, not a sequence of targeted repairs.

## Operate it through preview and force

Use `ProjectionCatalogOperations` and the mounted [operations console](operations-console.md), never a bespoke script. The non-forced preview reports the serving revision, target, dedup, stream-history, and work-admission facts; `--force` executes. The `keiro/catalog-stream-reprojection-preview/v2` and `keiro/catalog-stream-reprojection-outcome/v2` envelopes carry the event count, expected dedup claims, the reviewed and admitted maximum, cleared rows per target, replay and application counts, dedup inserted/existing counts, and verification. Typed refusals carry stable operator codes; branch on those, never on rendered text.

Record the preview and outcome with the operator, ticket, and binary revision like any other forced mutation.

## Related Patterns

- [Typed projection catalogs and rebuild groups](projection-catalogs.md)
- [Read models and projections](read-models-and-projections.md)
- [Keiro operations console](operations-console.md)
- [Kiroku replay-history retention](../kiroku/history-retention.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
