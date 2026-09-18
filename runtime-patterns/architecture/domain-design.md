---
type: Standard
title: "Domain Design And Runtime Choices"
description: "Design bounded contexts, invariants, aggregates, domain events, and workflows before service layout and runtime mechanisms"
timestamp: 2026-09-18T13:01:11Z
generated:
  by: process:codex
  at: "2026-09-18T13:01:11Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-domain-design
tags: [architecture, ddd, aggregates, invariants, domain-events, workflows]
status: current
---

# Domain Design And Runtime Choices

**Start with the business model: define the bounded context's language, invariants, aggregates, domain events, and workflows before choosing packages, generators, or transports.**

These standards govern one microservice platform with isolated DDD bounded
contexts. A bounded context owns its model, vocabulary, and private persistence.
Its public integration contracts connect it to other contexts without sharing
aggregate implementations or private database tables. Use the platform's
six application-package and DSL-first conventions after establishing that model.

## Establish The Context And Business Scenarios

Name the capability, its domain owner, and the terms that have a precise meaning
inside the context. Describe representative business scenarios in that language:
the initiating intent, prerequisites, accepted result, rejection, and later work.
Record which facts this context owns and which it learns from other contexts.
Translate incoming integration contracts into local domain concepts at the boundary.

Do not infer one aggregate per database table, screen, endpoint, or noun. A
bounded context can contain several aggregates. Choose deployment and package
boundaries to serve the context's ownership and operational needs.

## Assign Every Invariant An Owner

Write each invariant as a business statement, such as "a closed Conversation
cannot accept a message." Identify the authoritative state needed to decide it,
the aggregate that owns the decision, and the conflicting commands that could
violate it under concurrency.

An aggregate is one consistency boundary: one identity, one stream version,
and one validated transducer. Compose behaviors inside that boundary only when
they share its identity and atomic decision. Keep the state required for the
decision in that boundary; an asynchronously updated view cannot enforce a
strict invariant about current state.

If a rule spans independent aggregates, decide explicitly whether it requires
a redesigned boundary, a reservation owned by an aggregate, or an eventual
business process with compensation. A workflow or process manager does not
make independent stream commits atomic. A pure guard cannot enforce uniqueness
across unrelated streams by inspecting one stream's state.

Keep aggregates as small as their atomic invariants allow. Review contention,
history growth, and lifecycle together; package layout is not a reason to merge
independent identities into one stream. Follow
[transducer best practices](../keiki/transducer-best-practices.md) and
[checked composition](../keiki/checked-composition.md) when implementing the model.

## Specify Commands, Outcomes, And Domain Events

Commands express intent and may be refused. Domain events record accepted facts
in the context's language and carry the data needed to reproduce durable state.
Define each command's prerequisites, guards, state changes, emitted events,
business rejection, and no-op behavior before selecting its generated surface.

Keep decision logic deterministic. Capture relevant external facts, time, and
allocated identifiers as explicit inputs or recorded facts; do not consult a
network service during pure decision or replay. Reevaluate aggregate guards
after an optimistic-concurrency conflict.

Distinguish retrying the same intent from issuing a new command. Define its
[request identity and receipt policy](../keiro/command-cycle-and-errors.md#make-business-request-retries-explicit)
at the application boundary. Use [typed command outcomes](../keiro/command-cycle-and-errors.md)
so business rejections and no-ops do not become infrastructure failures.

Private domain events support this context's replay and evolution. Publish only
the selected facts other contexts need through separately versioned
[integration contracts](../messaging/integration-events.md); a private event is
not automatically a public contract. Use the [outbox](../messaging/outbox.md)
and [inbox](../messaging/inbox.md) at those delivery boundaries.

## Design The Business Workflow Before Selecting A Runner

Describe the process from intent to a business terminal outcome. Name its owner,
correlation identity, participating aggregates and contexts, pending states,
deadlines, cancellation rules, and compensation. Specify what happens when a
participant refuses, delivery repeats, or execution stops between effects.
Compensation is a new business action and may itself fail; it does not erase
committed history.

Choose the smallest mechanism that preserves those rules:

| Business responsibility | Runtime choice |
| --- | --- |
| One atomic decision over one identity | Validated aggregate stream |
| Derived query state | Inline or subscription projection with explicit freshness |
| Event-driven coordination with durable state, timers, or compensation | Process manager |
| A durable sequence with named steps, waits, callbacks, or child work | Durable workflow |
| Stateless event fan-out to selected targets | Router |
| Retryable operational work such as rendering or notification delivery | Work queue |

Use [process managers](../messaging/process-managers.md) and
[durable workflows](../keiro/durable-workflows.md) according to process shape.
Both require idempotent external effects; neither grants exactly-once delivery.
Coordinate across bounded contexts through their public contracts, not by
dispatching directly into their private streams.

## Define What A Caller May Observe

Specify whether the caller needs immediate command acceptance, an updated local
view, or the eventual completion of a cross-context process. These are different
business promises.

Use an inline projection when its state must commit with accepted events. Use a
subscription projection when lag is acceptable, with an explicit
[read-model freshness policy](../keiro/read-models-and-projections.md).
A committed command can succeed while a later query wait times out. Expose
pending workflow state when completion requires other participants; do not
present local acceptance as completion of the entire process.

## Prove The Model, Then Arrange Its Implementation

Before scaffolding, retain a small set of named business scenarios covering each
invariant, rejection, no-op, concurrent conflict, and workflow failure path.
Use them as acceptance examples for [behavior conformance](../keiro/behavior-conformance.md)
and application tests. Prove replay produces the same durable state and that
redelivery does not repeat a protected business effect.

Then apply [DSL adoption](../keiro/dsl-adoption.md), declare nominal
[domain values](domain-newtypes-and-typeids.md), and record the model in a
[service workspace](../keiro/service-workspaces.md). On Language 6,
generate expressible aggregate decisions and keep explicit holes for the
behavior the language cannot express. Choose [vertical modules](vertical-slice-modules.md),
[application packages](service-packages.md), and
[test layout](test-layout.md) around those responsibilities.
Select a [transport](../messaging/transport-selection.md) only after deciding
the interaction's ownership, durability, ordering, and replay requirements.

The [Conversation vertical](worked-example-conversation.md) demonstrates this
order with an illustrative aggregate and asynchronous follow-up work.
