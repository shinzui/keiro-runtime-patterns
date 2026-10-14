---
type: Standard
title: "Kiroku read-only inspection"
description: "Discover store inspection capabilities, page durable reads, preserve exact cursors, and recover live-tail loss"
timestamp: 2026-10-14T22:01:17Z
generated:
  by: process:codex
  at: "2026-10-14T22:01:17Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/kiroku-inspection
tags: [kiroku, inspection, operations]
status: current
---

# Kiroku read-only inspection

**Use public bounded reads for durable truth, discover actual server wiring, and treat live tails as hints that require recoverable cursors.**

Use `kiroku-store` 0.11.0.0, `kiroku-metrics` 0.3.0.0, and migrations 0.7.1.0. Apply migration 0015 during a planned write pause on large stores; its transactional browse-index build can block writes. This surface supplies reads, not retry, redrive, deletion, or database migration.

## Discover the answering process

Resolve `capabilities` relative to the configured base URL, retaining any mount prefix. Its route flags report installed providers and declared WebSocket channels, not database health. Preserve that prefix when deriving HTTP and `ws:`/`wss:` URLs.

Metrics, health, live subscriptions and WebSocket metrics describe the answering process. Durable checkpoints and dead letters survive stopped workers. `kiroku-inspect` opens its own store and collector but runs no subscriptions: an empty live registry says nothing about workers elsewhere. Serialize checkpoint polls; the durable inventory is unpaginated and proportional to row count.

Compose `storeServerProviders` with the provider-aware starters or `combinedAppWithProviders`. Build custom providers from `defaultServerProviders`; opaque custom WebSocket apps must declare their channels. Keep providers and server within bracketed resource lifetimes.

## Page through the public store surface

Use `listStreams`, `listCategories`, `getEvent`, and `subscriptionDeadLetters`; extend exhaustive custom `Store` interpreters for their constructors and `GetStreamWithHead`. Construct `BrowsePageSize` with `mkBrowsePageSize` (1–1001, including an HTTP over-fetch row); HTTP limits default to 100 and cap at 1000 unless the host lowers them. Dead-letter limits use `mkSubscriptionDeadLetterLimit` (1–1000).

`listStreams` uses UTF-8 byte order, an exact category, a literal prefix, and an exclusive stream-name cursor. `%` and `_` are literal. Soft-deleted streams remain visible; hard-deleted ones disappear. Category enumeration uses database locale order. TypeID name order is generation order, not event or commit order. Separate pages do not share a frozen snapshot.

Use `/streams`, `/categories`, `/events`, their detail/history routes, `/subscription-checkpoints`, and `/subscriptions/<name>/dead-letters`. Encode resource names as individual path segments. Echo each opaque `next_cursor` unchanged as `from`, retaining scope, filters and direction. Dead letters are newest first with an exclusive composite position/row-ID cursor; never derive it from position alone. Preserve unfamiliar structured reason variants.

Decode Int64 positions losslessly before using them as cursors. JavaScript `Number` loses values above 2^53; converting an already-rounded number to `BigInt` does not repair it. Per-stream event positions cannot manufacture a global cursor.

## Recover live-tail loss before advancing coverage

Use `/ws/events` with `subscribe_events`, optional `from_position` and `category`. Retain the last safe cursor and deduplicate replay/live overlap. On `event_stream_overflowed`, save the cursor from before the notice, treat subsequent surviving events as hints, and page HTTP history from that saved cursor before advancing covered progress. Apply the same recovery after reconnect. Numeric gaps alone do not prove loss.

`replay_failed`, `category_read_failed`, and `live_decode_failed` end the current tail; repair and resubscribe from the safe cursor. `unsubscribe_events` joins and releases it. `/ws/metrics` instead sends complete snapshots; `unsubscribe_metrics` stops periodic delivery and `subscribe_metrics` requests a fresh snapshot and resumes it.

## Serve browser access deliberately

CORS defaults off. Configure validated explicit origins; credentialed access requires explicit origins and wildcard origins are refused. CORS does not authenticate a caller. The standalone listener binds all interfaces and supplies no authentication, TLS, static UI or rate limiting; host it within the service's controlled operational access boundary.

New read routes support GET/HEAD and structured error codes. Existing health and metrics error shapes remain their published contract. Ignore additive fields and unknown vocabulary; branch on codes rather than messages. New keys, including `original_stream_name`, use snake_case; shipped event keys retain camelCase.

## Related Patterns

- [Append and read](append-and-read.md)
- [Subscription rules](subscriptions.md)
- [Durable checkpoint inventory](checkpoint-inventory.md)
- [Observability](observability.md)
- [Migration operations](../migrations/operations.md)
