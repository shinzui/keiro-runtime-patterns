---
type: Standard
title: "Kiroku durable checkpoint inventory"
description: "Reading one member-aware durable checkpoint snapshot without querying Kiroku-owned tables or mislabeling cursor distance as event lag"
timestamp: 2026-08-10T13:59:20Z
generated:
  by: human:nadeem
  at: "2026-08-10T13:59:20Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-checkpoint-inventory
tags: [kiroku, checkpoint-inventory]
status: current
---

# Kiroku durable checkpoint inventory

**Read durable subscription positions through `subscriptionCheckpointInventory`; never query Kiroku's checkpoint tables or infer the store head from visible events.**

Kiroku Store 0.4.0.0 publishes this operation. The package release is tagged and available from Hackage; upgrading an exhaustive custom or mock `Store` interpreter requires a `GetSubscriptionCheckpointInventory` arm.

## Consume one coherent snapshot

`subscriptionCheckpointInventory` returns the captured global store cursor and every persisted checkpoint from one prepared PostgreSQL statement snapshot. Use those values together. Do not issue a separate head read and combine observations from different instants.

The result is ordered by subscription name and consumer-group member. Preserve every member row and its `checkpointUpdatedAt`; do not collapse a group to member zero or discard rows merely because its worker is not currently live. Durable rows remain visible after workers stop, unlike the live subscription-state registry.

For a named subscription, derive the durable floor as the minimum checkpoint across its matching members. A missing name is an empty result with no synthetic member, checkpoint, or zero.

## Name cursor distance honestly

A global position is an opaque, strictly increasing cursor. Subtracting a checkpoint from the captured store cursor yields `global_position_distance`; it does not count relevant events. Category filters, consumer-group partitioning, linked or deleted history, and gaps in the cursor domain can all make the distance differ from work remaining.

Use `subscriptionPositionFromInventory` and `recordProjectionGlobalPositionDistance` in Keiro consumers. Retain the old projection-lag API only as a deprecated compatibility alias. Do not publish a metric or command named event lag until the owning projection supplies a compatible source frontier and definition.

## Keep observation separate from lifecycle mutation

The inventory is read-only. It does not initialize, reset, delete, or validate a subscription's intended first-run behavior. A missing checkpoint still requires the explicit from-beginning, from-current-head, or fail-if-missing decision from the subscription standard. Do not use inventory reads to hide the absence of an atomic lifecycle API.

## Related Patterns

- [Kiroku subscription patterns](subscriptions.md)
- [Kiroku operational invariants](operational-invariants.md)
- [Keiro operations console](../keiro/operations-console.md)
- [Read models and projections](../keiro/read-models-and-projections.md)
