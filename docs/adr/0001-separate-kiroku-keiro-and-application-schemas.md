# ADR 0001: Separate Kiroku, Keiro, and application schemas

## Status

Accepted — 2026-07-22

## Context

A Keiro service uses PostgreSQL for three different ownership domains. Kiroku's connection `schema` resolves the event log and determines its `LISTEN <schema>.events` channel. Keiro migrations own framework tables such as snapshots, timers, workflow state, and dead letters. Application projections have their own lifecycle and migration owner.

Using one namespace or relying on `search_path` hides those boundaries and can silently break Kiroku change notification.

## Decision

Keep the Kiroku store schema at its `kiroku` default, keep Keiro framework tables in the schema named by `Keiro.Schema.keiroSchema`, and place application tables in an application-owned schema.

Construct connections with `keiroConnectionSettings connString appSchema`. Application SQL that crosses a schema boundary uses `qualifyTable`; it does not hard-code the Keiro schema literal or address framework tables by an unqualified name. Migrations, not application startup code, create all three owners' tables.

## Consequences

- Kiroku notification and event-store resolution remain coupled to one explicit store contract.
- Keiro can evolve its framework schema independently of application projections.
- Cross-schema SQL is noisier but reviewable and independent of `search_path` ordering.
- Service migration plans must compose Kiroku, Keiro, and application components before traffic starts.

## Related Guidance

- [The two-schema arrangement](../../runtime-patterns/keiro/two-schema-arrangement.md)
- [Kiroku connection settings](../../runtime-patterns/kiroku/connection-settings.md)
- [Service migration packages](../../runtime-patterns/migrations/service-package.md)
