---
type: Standard
title: "Cross-Cutting Module Allowlist"
description: "The closed allowlist of technical-layer modules and the domain-vs-technology division heuristic"
timestamp: 2026-07-22T11:39:26-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/architecture-cross-cutting-modules
tags: [architecture, cross-cutting-modules]
status: current
---

# Cross-Cutting Module Allowlist

**A technical-layer module is allowed only when its name appears in this closed list.**

Most code belongs to a domain-concept vertical. The modules below are the narrow exceptions whose responsibility genuinely spans concepts or initializes a deployable role. The examples use danwa paths because danwa is the structural reference; substitute the new service's module root.

## Core Allowlist

`<Service>.Prelude` is the custom prelude re-export module. `<Service>.App.Config` is the application configuration record shared by runtime entry points. `<Service>.Postgres.Pool` acquires PostgreSQL pools, and `<Service>.Postgres.Runner` connects the event store and application configuration to hasql execution.

`<Service>.Api` is the umbrella servant route record that composes per-concept `<Service>.<Concept>.Api` modules. It defines no concept-specific route behavior.

`<Service>.Migrations` composes the service migration plan, and `<Service>.Migrations.New` implements the migration-file scaffold. They live in `<service>-migrations`, not in core.

`<Service>.Diagrams` renders Mermaid lifecycle diagrams from the domain transducers. It backs the diagrams executable and its drift-check suite; it is real shared infrastructure, not a placeholder namespace.

## Deployable-Role Allowlist

The HTTP package may contain `<Service>.Server.App`, `<Service>.Server.Boot`, `<Service>.Server.Config`, and `<Service>.Server.Seam`. They own, respectively, the WAI application, startup, server-specific configuration, and the explicit conversion between keiro command results and HTTP errors.

The worker package may contain `<Service>.Workers.Config`, `<Service>.Workers.Registry`, and `<Service>.Workers.Subscription`. They own worker configuration, composition of the service's processor registry, and shared subscription plumbing. The registry composes concept workers; it does not absorb their behavior.

## Exclusions

Placeholder umbrella modules such as danwa's dead `Danwa.Core` are not part of the standard. Do not create an empty module solely because its package is named `-core`.

`<Service>.Integration` is not a technical-layer exception. Integration contracts, inboxes, outboxes, and their workers form a first-class domain vertical because they express the service boundary. Place them under `<Service>.Integration.*` as described in [extended node verticals](extended-node-verticals.md).

## Division Heuristic

If a module's name names a domain concept, put it in that concept's vertical. If its name names a technology or runtime role, it must justify itself against this allowlist. When the proposed name is absent, move the code to the concept or integration vertical that owns the behavior.

```text
WRONG
  Danwa.Kafka.Publishers
    publishes Conversation, Message, and AddressedMessage events

CORRECT
  Danwa.Conversation.<ConceptSpecificPublisherOrWorker>
  Danwa.Message.<ConceptSpecificPublisherOrWorker>
  Danwa.Integration.OutboxPublisherWorker
  Danwa.Workers.Registry                  -- composes them only
```

The allowlist is closed by design. Adding another technical namespace is an architecture decision: update this standard and record why no domain vertical can own the behavior before introducing it to a service.

## Related Patterns

- [Service packages](service-packages.md)
- [Vertical-slice modules](vertical-slice-modules.md)
- [Extended node verticals](extended-node-verticals.md)
- [Messaging patterns](../messaging/overview.md)
