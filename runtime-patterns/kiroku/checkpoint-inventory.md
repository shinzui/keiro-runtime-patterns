---
type: Standard
title: "Kiroku durable checkpoint inventory"
description: "Reading one member-aware durable checkpoint snapshot in-process or through the frozen v1 relation, without mislabeling cursor distance as event lag"
timestamp: 2026-08-14T17:48:00Z
generated:
  by: human:nadeem
  at: "2026-08-14T17:48:00Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-checkpoint-inventory
tags: [kiroku, checkpoint-inventory]
status: current
---

# Kiroku durable checkpoint inventory

**Read durable subscription positions through `subscriptionCheckpointInventory`; never query Kiroku's checkpoint tables or infer the store head from visible events.**

Kiroku Store 0.4.0.0 publishes this operation. Upgrading an exhaustive custom or mock `Store` interpreter requires a `GetSubscriptionCheckpointInventory` arm.

## Consume one coherent snapshot

`subscriptionCheckpointInventory` returns the captured global store cursor and every persisted checkpoint from one prepared PostgreSQL statement snapshot. Use those values together. Do not issue a separate head read and combine observations from different instants.

The result is ordered by subscription name and consumer-group member. Preserve every member row and its `checkpointUpdatedAt`; do not collapse a group to member zero or discard rows merely because its worker is not currently live. Durable rows remain visible after workers stop, unlike the live subscription-state registry.

For a named subscription, derive the durable floor as the minimum checkpoint across its matching members. A missing name is an empty result with no synthetic member, checkpoint, or zero.

## Give a database reader the frozen relation, not the table

An out-of-process reader must never receive access to `kiroku.subscriptions`. Migration `0009` publishes `kiroku.subscription_checkpoints_v1`, an owner-rights, structurally read-only relation whose four columns — `subscription_name`, `consumer_group_member`, `checkpoint_position`, `checkpoint_updated_at` — and their order are frozen. Grant schema usage and select on that relation, and nothing else; Kiroku creates no role and no grant automatically.

Read it with the same care as the in-process inventory. Its rows are unordered unless the caller supplies `ORDER BY`; member zero does not distinguish a non-group subscription from member zero of a consumer group; `checkpoint_updated_at` is the time of the latest upsert and implies neither position advancement nor worker liveness; and an explicit reset may have moved a position backward.

## Name cursor distance honestly

A global position is an opaque, strictly increasing cursor. Subtracting a checkpoint from a store head yields `global_position_distance`; it does not count relevant events. Category filters, consumer-group partitioning, linked or deleted history, and gaps in the cursor domain can all make the distance differ from work remaining.

Subtract from the **visible** head, not the authoritative append frontier: hard deletion of the visible tail can leave a frontier no consumer will ever reach. Keep the frontier for operator reporting of how far the store has advanced. See [append and read patterns](append-and-read.md).

Use `subscriptionPositionFromInventory` and `recordProjectionGlobalPositionDistance` in Keiro consumers. Retain the old projection-lag API only as a deprecated compatibility alias. Do not publish a metric or command named event lag until the owning projection supplies a compatible source frontier and definition.

## Keep observation separate from lifecycle mutation

The inventory is read-only. It does not initialize, reset, delete, or validate a subscription's intended first-run behavior. A missing checkpoint still requires the explicit from-beginning, from-current-head, or fail-if-missing decision from the subscription standard. Do not use inventory reads to hide the absence of an atomic lifecycle API.

## Related Patterns

- [Kiroku subscription patterns](subscriptions.md)
- [Kiroku append and read patterns](append-and-read.md)
- [Kiroku operational invariants](operational-invariants.md)
- [Keiro operations console](../keiro/operations-console.md)
- [Read models and projections](../keiro/read-models-and-projections.md)
