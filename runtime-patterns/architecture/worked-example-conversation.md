---
type: Pattern
title: "Worked Conversation Vertical"
description: "Conversation vertical illustrating domain-first design and current generated/hand-owned ownership"
timestamp: 2026-09-18T13:01:11Z
generated:
  by: process:codex
  at: "2026-09-18T13:01:11Z"
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

**Design the Conversation aggregate's invariants and events first, then map its responsibilities into the current workspace and vertical layout.**

The original example described the legacy Conversation slice in
`mori://shinzui/danwa`, with a bare service source and a whole transducer in
`Holes`. That historical layout explains existing code; it is not the
replication template for a new Language 5 service. The design below is an
illustrative current-language adaptation, not a claim about that repository's
present files or business rules.

## State The Business Rules

Suppose a Conversation may be started, receive messages while open, and close.
State the rules before writing a specification:

- one Conversation identity owns its lifecycle and message-acceptance decisions;
- appending a message to a closed Conversation is rejected;
- closing an open Conversation emits a domain event; closing an already closed
  Conversation is an explicitly modeled no-op;
- summary generation may finish later and does not determine whether a message
  was accepted.

Name commands in the context's language: `StartConversation`, `AppendMessage`,
and `CloseConversation`. Name private domain facts in the past tense:
`ConversationStarted`, `MessageAppended`, and `ConversationClosed`.
Record the data needed to reproduce each accepted decision during replay.
These are example modeling choices; establish the real domain's rules with its
owners before adopting them.

## Declare The Model And Its Ownership

Use `domain/<service>.keiro-workspace` with a complete Conversation member
under `domain/<service>/`. Declare Language 6 in each member, collocated
placement in the manifest, and `runtime-package <service>-core`.

Declare the expressible guards, updates, emitted events, rejection reasons,
and no-op reasons in the aggregate member. Let the generated transducer own
them. Use `implementation hole` for a specific behavior the language cannot
express, then provide its implementation and conformance witnesses. Never
copy an entire legacy hand-written transducer over generated ownership.

Keep command/event types, codecs, transducer assembly, and behavior contracts
in the generated ring. Fill only the create-once hooks, bindings, and witnesses
reported by scaffolding. Query SQL, API DTOs, request orchestration, and worker
implementations remain application-owned. The emitted manifest and
[vertical-slice standard](vertical-slice-modules.md) determine the actual files.

## Execute Commands And Serve Their Results

The API handler translates a request into a domain command, establishes its
[retry contract](../keiro/command-cycle-and-errors.md#make-business-request-retries-explicit),
and invokes the generated domain handler through a validated stream. Handle
accepted, rejected, and no-op outcomes separately.

```text
Request → application handler → validated aggregate → decision → atomic event append
```

Choose inline catalog projections when the query state must commit with the
accepted events. Otherwise use a subscription projection with an explicit
freshness policy. When the caller must observe its accepted write through an
asynchronous model, return its committed position and use a supported position
wait. A timeout after commit does not undo acceptance or justify issuing a new
business command.

## Coordinate Work Outside The Aggregate

Project a queryable Conversation view from private domain events. Projection
handlers must reproduce the same rows on replay and tolerate redelivery.

Treat summary generation as a job if it is independent operational work. If
the business process instead has deadlines, durable decisions, and compensation,
model that process explicitly with a process manager or durable workflow.
Keep the Conversation aggregate authoritative for its own invariants.

If another bounded context needs a Conversation fact, map it to an explicitly
owned integration contract and publish through the outbox. Do not share private
event types or read the Conversation tables from that context.

## Prove The Vertical

Test acceptance, rejection after closure, repeated close, and replay. Race
message acceptance with closure and assert that the final history obeys the
chosen invariant. Test a retry after a lost response, projection redelivery,
and the declared query freshness behavior. For summary work, test duplicate
delivery and failure recovery.

Run the generated conformance package against `<service>-core`; keep these
application-level scenarios in the owning core, server, and worker suites.
The six application packages remain the deployment structure, with generated
conformance tooling additional.

## Related Patterns

- [Domain design and runtime choices](domain-design.md)
- [Specification and scaffolding](spec-and-scaffolding.md)
- [Aggregate transition ownership](../keiro/aggregate-expressions.md)
- [Test layout](test-layout.md)
- [Read models and projections](../keiro/read-models-and-projections.md)
- [Process managers](../messaging/process-managers.md)
