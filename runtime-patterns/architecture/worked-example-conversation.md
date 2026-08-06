---
type: Pattern
title: "Worked Conversation Vertical"
description: "Complete file listing of danwa's Conversation slice across all six packages"
timestamp: 2026-07-22T18:54:19Z
generated:
  by: human:nadeem
  at: "2026-07-22T18:54:19Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-worked-example-conversation
tags: [architecture, worked-example-conversation]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T18:54:19Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved danwa and keiro-runtime-jitsurei reference applications and the keiro-dsl scaffolder at HEAD; verified exported symbols, signatures, version claims, and links.
---

# Worked Conversation Vertical

**Danwa's Conversation slice shows one aggregate from specification through API, command execution, projection, and worker tests.**

This example is a complete real vertical from the danwa structural reference. Every path below exists in the danwa checkout. Copy the shape for a new concept, then replace Conversation-specific commands, events, data, and handlers with the new domain behavior.

## Complete File Listing

```text
domain/danwa.keiro
  declares the aggregate, projection, and operations

danwa-core/src/Danwa/Conversation/Generated/Domain.hs
  generated: identifiers, commands, events, registers, and predicates
danwa-core/src/Danwa/Conversation/Generated/Codec.hs
  generated: persisted event codec
danwa-core/src/Danwa/Conversation/Generated/EventStream.hs
  generated: validated stream definition
danwa-core/src/Danwa/Conversation/Generated/Projection.hs
  generated: inline projection wiring
danwa-core/src/Danwa/Conversation/Generated/Harness.hs
  generated: validation and round-trip assertions
danwa-core/src/Danwa/Conversation/Holes.hs
  hand: keiki transducer and applyConversations event fold
danwa-core/src/Danwa/Conversation/ReadModel.hs
  hand: rows, hasql codecs, and statements

danwa-api/src/Danwa/Conversation/Api.hs
  hand: NamedRoutes and wire DTOs
danwa-server/src/Danwa/Conversation/Handler.hs
  hand: route handlers

danwa-workers/src/Danwa/Conversation/Worker.hs
  hand: projection worker
danwa-workers/src/Danwa/Conversation/AgentSummaryWorker.hs
  hand: Conversation-side PGMQ-backed process
danwa-workers/test/Danwa/Conversation/WorkerSpec.hs
  hand: projection worker tests
danwa-workers/test/Danwa/Conversation/AgentSummaryWorkerSpec.hs
  hand: process tests
```

## What The Scaffolder Owns

Keiro-dsl regenerates the five `Generated.*` core modules on every scaffold run. Their header banner makes that ownership explicit. It creates `Holes.hs` only when absent, then skips the file forever; developers fill it with the aggregate transducer and projection apply function. `ReadModel.hs`, API, handler, workers, and worker specs are also hand-owned.

The two core modules edited during ordinary domain work are `Holes` and `ReadModel`. Change structural declarations in `domain/danwa.keiro`, not in the generated ring. Change domain decisions and event folding in `Holes`. Change query rows, codecs, and SQL in `ReadModel`.

## Command Flow

A request enters `Danwa.Conversation.Api` as a typed servant route and DTO. `Danwa.Conversation.Handler` converts it to a domain command and runs the validated stream from `Generated.EventStream`. The stream hydrates prior events and applies the keiki transducer defined in `Holes`; accepted events are appended to kiroku. Generated `Domain` and `Codec` modules supply the checked domain and persistence shapes throughout the flow.

```text
Api → Handler → Generated.EventStream → Holes transducer → kiroku append
```

## Event-To-Query Flow

A Shibuya Kiroku subscription delivers a recorded event to `Danwa.Conversation.Worker`. The worker invokes `applyConversations` from `Holes` inside the projection transaction. That fold executes statements declared by `ReadModel`, updating the application-owned query table. The worker spec proves this boundary using an ephemeral migrated database.

```text
kiroku subscription → Worker → Holes.applyConversations → ReadModel table
```

## Replicate The Slice

To add concept `<New>`, declare it in `domain/<service>.keiro`, run the checked re-scaffold workflow, and then create or fill exactly the hand-owned surfaces the concept needs: `Holes`, `ReadModel`, `Api`, `Handler`, `Worker`, and `WorkerSpec`. A concept with several distinct processes may add more concept-named workers and matching specs; it does not move them into a technical worker namespace.

## Related Patterns

- [Vertical-slice modules](vertical-slice-modules.md)
- [Specification and scaffolding](spec-and-scaffolding.md)
- [Test layout](test-layout.md)
- [Command cycle and errors](../keiro/command-cycle-and-errors.md)
- [Kiroku subscriptions](../messaging/kiroku-subscriptions.md)
