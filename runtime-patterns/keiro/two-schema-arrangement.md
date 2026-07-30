---
type: Guide
title: "The two-schema arrangement"
description: "Separation of Kiroku store, Keiro framework, and application-owned PostgreSQL schemas"
timestamp: 2026-07-22T10:46:22-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-two-schema-arrangement
tags: [keiro, two-schema-arrangement]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T10:46:22-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# The two-schema arrangement

**One service, two framework schemas: `kiroku` owns the log and notifications, while `keiro` owns runtime tables—qualify everything.**

This standard separates event-store infrastructure, keiro runtime infrastructure, and application data so each migration owner and connection contract remains explicit.

## Keep the namespaces separate

The rule is one sentence: leave the kiroku connection schema at `kiroku`, let keiro migrations own `keiro`, and place projections in an application-owned schema.

Kiroku resolves event-log tables and subscribes to `LISTEN <schema>.events` through its connection `schema`. Pointing that setting at `keiro` breaks the store contract rather than configuring the runtime. Keiro's framework SQL is instead fully qualified against the schema named by `Keiro.Schema.keiroSchema`; do not duplicate its current value, `"keiro"`, in application code.

Application read-model tables conventionally occupy a third schema. Construct the pool with `keiroConnectionSettings connString appSchema`; it adds the application schema to `extraSearchPath` while keiro continues to address its own tables explicitly.

## Qualify cross-schema SQL

The rule is one sentence: application SQL that names framework or cross-schema tables must build identifiers with `qualifyTable`.

`qualifyTable :: Text -> Text -> Text` produces a double-quoted `"schema"."table"` reference. Applications should normally use public runtime operations rather than query framework tables, but diagnostic or coordinating SQL must still follow this rule.

```haskell
-- CORRECT: follows the runtime's schema constant and quotes both identifiers.
selectDueTimers =
  "SELECT * FROM " <> qualifyTable keiroSchema "keiro_timers" <>
  " WHERE wake_at <= now()"

-- WRONG: depends on search_path and may resolve nowhere or to the wrong table.
selectDueTimers =
  "SELECT * FROM keiro_timers WHERE wake_at <= now()"
```

## Migrate before startup

The rule is one sentence: run `keiro-migrate up` before the application starts; never create framework tables from application code.

The native pg-migrate plan applies kiroku's component before keiro's component, then creates and evolves the dedicated runtime schema. For migration details, see the keiro repo's `docs/user/migrations.md` and `docs/user/upgrading-to-the-keiro-schema.md`.

## Related Patterns

- [Keiro runtime patterns](overview.md)
- [Kiroku event-store patterns](../kiroku/overview.md)
- [Migration standards](../migrations/overview.md)
