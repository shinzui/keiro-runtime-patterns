---
type: Standard
title: "TypeID prefix naming"
description: "Choose durable TypeID prefixes from the domain's ubiquitous language instead of an arbitrary abbreviation budget"
timestamp: 2026-09-01T15:59:19Z
generated:
  by: human:nadeem
  at: "2026-09-01T15:59:19Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-typeid-prefix-naming
tags: [keiro, typeid, identity, ubiquitous-language]
status: current
---

# TypeID prefix naming

**Use the singular, lowercase `snake_case` name from the domain's ubiquitous language; a TypeID prefix is a durable type label, not a short encoding budget.**

The [domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md) standard decides which values are service-owned identities and requires a TypeID-backed nominal type for each. This standard chooses the prefix once that decision is made.

The prefix appears in database rows, URLs, logs, traces, fixtures, support conversations, and copied identifiers. It should tell a person what the identifier denotes without requiring a legend. The TypeID library admits lowercase ASCII letters and underscores and has a hard 63-character prefix ceiling. That ceiling is an interoperability limit, not a target.

## Default to the full domain noun

Choose the term domain experts use for the entity, aggregate, or durable message kind:

| Avoid | Prefer |
|---|---|
| `proj` | `project` |
| `part` | `project_artifact` |
| `aut` | `automation` |
| `rxn` | `reaction` |
| `wf` | `workflow` |
| `sige` | `signal_emission` |
| `sigd` | `signal_delivery` |

Use singular nouns because one TypeID denotes one thing. Add a qualifier only when it distinguishes concepts that the domain actually treats as different. Do not add a service name, table name, storage technology, or bounded-context name merely to make the prefix globally unique.

Do not impose a three-, four-, or eight-character house limit. Abbreviate only when the full ubiquitous term approaches the hard limit or is demonstrably unusable on an important constrained surface. The abbreviation must itself be a term the domain uses and understands; document that decision beside the declaration. Removing vowels, taking initials, or inventing an operator-only code is not an acceptable default.

## Keep locators separate from entity identity

A slug, provider key, composite natural key, or other logical locator is not an entity TypeID. Store a durable locator-to-TypeID reservation and mint new entity IDs with UUIDv7. Do not decorate a deterministic UUID from a locator with a TypeID prefix and then present it as a UUIDv7 identity.

This separation preserves both promises: callers can retry creation by the same locator, while the entity ID still belongs to the frozen TypeID-v7 domain described by [enforced identifier domains](identifier-domains.md).

## Treat a prefix change as a migration

The prefix is part of the serialized identifier domain. Renaming `rxn_...` to `reaction_...` changes persisted values, APIs, fixtures, routing keys, and operator input; it is not a cosmetic refactor.

Apply this standard to every new identifier. Existing short prefixes may remain when migration cost exceeds the readability benefit. If a rename is justified, inventory every durable reader and writer, introduce an explicit compatibility or migration path, and use the rollout gates in [evolution gates and rollout ordering](evolution-and-rollout.md). Never make two prefixes silently denote the same current domain without a documented boundary.

## Review checklist

Before accepting a new `typeid` prefix, verify that:

1. it is the singular term used in domain conversation and documentation;
2. a support engineer can identify the kind from the prefix alone;
3. every qualifier represents a real domain distinction;
4. any abbreviation is domain language with a recorded reason;
5. the value is a true UUIDv7 entity ID rather than an encoded locator; and
6. the team has treated any change to an existing prefix as a durable migration.

## Related Patterns

- [Enforced identifier domains](identifier-domains.md)
- [Domain newtypes and TypeIDs](../architecture/domain-newtypes-and-typeids.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Evolution gates and rollout ordering](evolution-and-rollout.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
